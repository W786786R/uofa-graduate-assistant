import requests
import json
from data_retrieval_from_RAG import retrieve_relevant_chunks


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


#This function checks whether  the user's message is  a greetings message.
def classify_message(text):
    text = text.strip().lower()

    greeting_keywords = ["hi", "hello", "hey", "good morning", "good afternoon", "good evening", "greetings", "what's up"]

    # Greeting check
    if text in greeting_keywords:
        return "greeting"


#This function gets the response from Llama 3.2 based on the user's message
# It takes the user's message and sends it to the RAG pipeline to retrieve the top 5 most relevant chunks
# After retrieving the relevant chunks, it sends the user's message and the relevant chunks to Llama 3.2 to get the response and returns the response
def get_llama_response(current_user_message: str) -> str:
    #The URL of the Llama 3.2 API endpoint in Ollama if we are running it locally
    url = "http://localhost:11434/api/chat"



    #If the user's message is a greeting, it is sent to Llama 3.2 as is
    if classify_message(current_user_message.message) == "greeting":
        prompt = f"{current_user_message.message}"

        payload = {
            "model": "llama3.2",
            "messages": [
                {"role": "user", "content": prompt},
            ]
        }

        #This receives the response from Llama 3.2
    else:
        # Retrieve relevant chunks from RAG
        relevant_chunks = retrieve_relevant_chunks(current_user_message.message)

        # We need to send the user's message and the relevant chunks to Llama 3.2 in a certain format. We are structuring the prompt to be sent to Llama 3.2.
        prompt = f"""
        Context:
        {relevant_chunks}

        Question:
        {current_user_message.message}
        """

        #The payload is the prompt that is sent to Llama 3.2. The system prompt is the instructions for the model. The user prompt is the user's message and the relevant chunks.
        payload = {
            "model": "llama3.2",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt},
            ]
        }

    response = requests.post(url, json=payload, stream=False)
    #We send the full response from Llama 3.2 to the user at once, not streaming it.
    full_response = ""
    for line in response.iter_lines():
        if line:
            data = json.loads(line.decode('utf-8'))
            if "message" in data and "content" in data["message"]:
                full_response += data["message"]["content"]
    print(full_response)
    return full_response