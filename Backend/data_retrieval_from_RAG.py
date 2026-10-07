
import chromadb
from chromadb.utils.embedding_functions import SentenceTransformerEmbeddingFunction
from sentence_transformers import CrossEncoder


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


#This function receives a query from the user and returns the top 10 most relevant chunks from the vector collection
def query_collection(prompt: str, n_results: int = 10):
    collection = get_vector_collection()
    results = collection.query(query_texts=[prompt], n_results=n_results)
    return results.get("documents")[0], results.get("metadatas")[0]


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

#This function combines the above functions to retrieve the top 5 most relevant chunks from the vector collection and returns them to Llama 3.2
def retrieve_relevant_chunks(query: str) -> list[str]:
    top_10_context, corresponding_metadata = query_collection(query)
    top_3_documents = re_rank_cross_encoders(top_10_context, corresponding_metadata, query)
    return top_3_documents
