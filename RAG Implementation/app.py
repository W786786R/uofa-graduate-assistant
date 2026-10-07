from pathlib import Path
import requests
import json
import chromadb
from chromadb.utils.embedding_functions import SentenceTransformerEmbeddingFunction
from langchain_community.document_loaders import PyMuPDFLoader
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from sentence_transformers import CrossEncoder

#This system prompt is sent to Llama 3.2 to answer the user's question only based on the context provided.
system_prompt = """
You are an AI assistant designed to answer user questions using only the information explicitly provided in the context below. You must not use any external knowledge, assumptions, or generalizations.

- The context will appear after "Context:"
- The question will appear after "Question:"

Your task is to:
1. Carefully read and extract only relevant information from the context. Always attach the source information provided in the context with your answer.
2. Directly answer the question based solely on the extracted information.
3. You MUST provide the source of the information with your answer.
4. If the context does not contain enough information to answer the question, clearly state: "The context does not provide enough information to answer this question.". In that case, do not provide any information about the source and context.


Important:
Your entire response must be grounded only in the provided context and the question. Avoid assumptions or filler statements.
"""

#This dictionary maps the PDF file names to the URLs of the pages in the University of Alberta website.
#We use this dictionary to add the URL to the metadata source of the Document object.
pdf_to_url = {
    "Admission.pdf": "https://www.ualberta.ca/en/computing-science/graduate-studies/programs-and-admissions/applications-and-admissions/index.html",
    "Multimedia.pdf": "https://www.ualberta.ca/en/computing-science/graduate-studies/programs-and-admissions/multimedia.html",
    "Tuition fees.pdf": "https://www.ualberta.ca/en/admissions-programs/tuition/index.html",
    "Adam White.pdf": "https://apps.ualberta.ca/directory/person/amw8",
    "Irene Cheng.pdf": "https://apps.ualberta.ca/directory/person/locheng",
    "Anup Basu.pdf": "https://apps.ualberta.ca/directory/person/basu",
    "Nidhi Hegde.pdf": "https://apps.ualberta.ca/directory/person/nidhih",
    "Rupam Mahmood.pdf": "https://apps.ualberta.ca/directory/person/ashique"
}


#This function is used to process the PDF files as follows:
# 1. Load the PDF files from the provided directory
# 2. Convert each to text chunks
# 3. Create embeddings for the text chunks
# 4. Store the embedded chunks in the vectorDB.
#We call this function to create the vector database with the documents in the data directory. We use this DB in our Mobile app.
def process_and_store_pdfs_in_directory(directory_path: str):

    # Get all PDF files in the provided directory
    pdf_files = Path(directory_path).rglob("*.pdf")
    
    # Process each PDF file in the directory
    for pdf_file in pdf_files:
        try:
            # Process the PDF file and get the document splits
            with open(pdf_file, "rb") as file:
                all_splits = process_document(file)
                
            # Add the processed document splits to the vector collection
            add_to_vector_collection(all_splits, pdf_file.stem)
            
            # Display success message using print
            print(f"Successfully processed and added '{pdf_file.stem}' to the vector store.")
        
        except Exception as e:
            # If there is an error, display it
            print(f"Error processing file '{pdf_file.stem}': {e}")


#This function is used to process the PDF files as follows:
# 1. Convert the PDF file to a temporary file
# 2. Load the temporary file using PyMuPDFLoader
# 3. Split the document into smaller chunks
# 4. Return the list of Document objects containing the chunked text
def process_document(pdf_file) -> list:
    try:
        # Load the document from the temporary file
        loader = PyMuPDFLoader(pdf_file.name)
        docs = loader.load()
        docs[0].metadata["source"] = pdf_to_url[pdf_file.name.split("\\")[-1]] #Change the source of the document from PDF file to the URL of the page in the University of Alberta website

        # Split documents into smaller chunks with a chunk size of 600 and a chunk overlap of 100
        # The separators are used to split the document into smaller chunks
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=600,
            chunk_overlap=100,
            separators=["\n\n", "\n", ".", "?", "!", " ", ""]
        )
        return text_splitter.split_documents(docs)

    except Exception as e:
        # Handle errors with file reading or processing
        raise IOError(f"Error processing PDF file: {e}")


#This function is used to get the vector collection- Chroma DB. This function is called when the user sends a query to the RAG pipeline.
#We also set the embedding mode = "all-MiniLM-L6-v2" to be used for the vector collection
#The collection name is "document_qa" that stores the embedded documents
#For similarity search, we use the "cosine" distance metric
def get_vector_collection() -> chromadb.Collection:
    embedding_function = SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")
    chroma_client = chromadb.PersistentClient(path="./chroma_db")
    return chroma_client.get_or_create_collection(
        name="document_qa",
        embedding_function=embedding_function,
        metadata={"hnsw:space": "cosine"},
    )


#This function is used to add the processed document splits to the vector collection
# 1. Get the vector collection
# 2. Create a list of documents, metadatas, and ids
# 3. Upsert the documents, metadatas, and ids into the vector collection
def add_to_vector_collection(all_splits: list[Document], file_name: str):
    collection = get_vector_collection()
    documents, metadatas, ids = [], [], []

    for idx, split in enumerate(all_splits):
        documents.append(split.page_content) #Add the page content to the list of documents
        metadatas.append({"source": split.metadata["source"]}) #Add the source to the list of metadatas
        ids.append(f"{file_name}_{idx}") #Add the id to the list of ids

    collection.upsert(
        documents=documents,
        metadatas=metadatas,
        ids=ids,
    )
    print("Data added to the vector store!")

#This function receives a query from the user and returns the top 10 most relevant chunks from the vector collection
def query_collection(prompt: str, n_results: int = 10):
    collection = get_vector_collection()
    results = collection.query(query_texts=[prompt], n_results=n_results)
    return results.get("documents")[0], results.get("metadatas")[0]

#This function is used to call the LLM to answer the user's query.
#We use this function to test the RAG pipeline before integrating it in the Mobile app.
def call_llm(context: str, prompt: str) -> str:
    url = "http://localhost:11434/api/chat"
    
    #The payload is the prompt that is sent to Llama 3.2. The system prompt is the instructions for the model. The user prompt is the user's message and the relevant chunks.
    payload = {
        "model": "llama3.2",
        "messages": [
            {
                "role": "system",
                "content": system_prompt,
            },
            {
                "role": "user",
                "content": f"Context: {context}\n\nQuestion: {prompt}",
            },
        ]
    }

    response = requests.post(url, json=payload, stream=True)

    #We send the full response from Llama 3.2 to the user at once, not streaming it.
    full_response = ""
    for line in response.iter_lines():
        if line:
            data = json.loads(line.decode("utf-8"))
            if "message" in data and "content" in data["message"]:
                full_response += data["message"]["content"]

    return full_response

#This function re-ranks the top 10 most relevant chunks from the vector collection using the cross-encoder model and returns the top 5 most relevant chunks to Llama 3.2
#It also adds the source of the document to the relevant chunks
def re_rank_cross_encoders(documents: list[str], metadata: list[dict], prompt: str) -> tuple[str, list[int]]:
    relevant_text = ""

    encoder_model = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")
    ranks = encoder_model.rank(prompt, documents, top_k=5)
    for rank in ranks:
        idx = rank["corpus_id"]
        source = metadata[idx].get("source", "unknown") #Get the source of the document from the metadata
        relevant_text += f"{documents[idx]}\n[Source: {source}]\n\n" #Add the source to the relevant chunks/texts

    return relevant_text



#Call this function to process the PDF files and store them in the vector collection
#process_and_store_pdfs_in_directory("./data")

#Test the RAG pipeline with different prompts
# prompt = "What is the minimum IELTS score required for MSc application?"
# top_10_context, corresponding_metadata = query_collection(prompt)
# top_3_documents = re_rank_cross_encoders(top_10_context, corresponding_metadata, prompt)

# print(call_llm(top_3_documents, prompt))


