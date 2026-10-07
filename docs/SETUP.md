Project Title: U of A Graduate Assistant

The project is divided into 5 parts:
1. Dataset Extraction
2. Backend
3. Frontend
4. RAG Implementation
5. Ollama Server

Each part has separate instructions to run properly. Please follow the instructions given below to run each code.

NOTE:
1. Running Dataset Extraction script is optional as the data has been already extracted and included in the RAG Implementation 'data' folder. However, instructions to run the script is included in the "Dataset Extraction" folder as a README file.

2. Running the RAG Implementation code is optional as it creates a vector database and tests the Llama 3.2 response. The vector database is already integrated in the Backend folder.
So this application has no direct connection with the Backend and Frontend.

But in order to run the Frontend application successfully, the Backend and Ollama server MUST be running.

2. Ollama server is not included in the source codes as it was not developed by us. However, in order to run and interact with Llama 3.2 locally, Ollama server must be running the Llama 3.2 in the backend.

 ----------------------------------------------------------------------------
|			Install and Run Ollama with Llama 3.2	     	     |
 ----------------------------------------------------------------------------
Instructions to install and run Ollama with Llama 3.2:

1. Go to the following link and download Ollama as per your operating system:

			https://www.ollama.com/download

2. After downloading Ollama, install it like any other software.

3. To check Ollama has been install successfully, go to the terminal/command prompt and write the following command:

			ollama --version

   If this gives you a version, it means Ollama has been installed successfully.

4. Now in the terminal/command prompt, write the following command to download Llama 3.2 model:

			ollama pull llama3.2

   This should download the Llama 3.2 model in Ollama.

5. To check if the model has been downloaded successfully, write the following command:

			ollama list

   This should show you the llama3.2 model information.

6. Now to run the llama 3.2 model, write the following command:

			ollama run llama3.2

   This will open up a chatting prompt with llama 3.2 . If you wish, you can chat with the llama 3.2 by writing your messages in the terminal/command prompt. To exit the chatting prompt write /bye .

7. By default Ollama should always be using the available GPU. But to check, you can write the following command:

			ollama ps

   It should show you the running LLM models and which hardware the models are using.

NOTE:
If the LLM does not receive any prompts for some time, Ollama automatically shuts the model down. So make sure to run the command in step 6 before running the frontend application.


		
 ----------------------------------------------------------------------------
|				Backend Server				     |
 ----------------------------------------------------------------------------
Instructions for running the Backend server:

1. Make sure Python 3.13.1 or greater is installed.

2. Open the Backend folder from VSCode.

3. Open a terminal, create and activate a virtual environment using the following commands:
	Create venv: python -m venv venv

	Activate venv: 
		for windows: venv\Scripts\activate
		for macOS/Linux: source venv/bin/activate

4. After activating the venv, make sure PIP is installed. If PIP is not installed, use the following command to install it:
		for windows: py -m pip install --upgrade pip setuptools wheel
		for macOS/Linux: python3 -m pip install --upgrade pip setuptools wheel


5. Then install the required libraries from requirements.txt file using the following command:
				
		pip install -r requirements.txt


6. After that use the following command to run the backend server:

		uvicorn main:app --host 0.0.0.0 --port 8000 --reload

This will run the backend server in localhost. To test if the backend server is running, you can go to the browser and type http://127.0.0.1:8000/docs in the address bar.
It should open SWAGGER UI of the FastAPI server that will display all of the APIs.

If you see any missing dependencies, install them using:
pip install package_name



 ----------------------------------------------------------------------------
|			  Frontend Application  			     |
 ----------------------------------------------------------------------------
Pre-requisites:
	Ensure the following are installed on your system:
		1. Flutter SDK (Version 3.29.0 or later recommended)

		2. Dart (comes with Flutter)

		3. Android Studio / VS Code (recommended) with Flutter & Dart plugins

		4. Android Emulator or physical device for testing

		5. Internet connection (to install dependencies)

	You can follow this tutorial from the Flutter official website to complete the installation process: https://docs.flutter.dev/get-started/install
		1. Select the operating system.
		2. Select Android as application type.
		3. Follow the given instructions sequentially.

Instructions for running the Frontend application:
1. Open the Frontend folder from VSCode.
2. Use the following command to install all of the dependencies available in pubspec.yaml file:
		
		flutter pub get

3. To check the connected devices available to run the application, write the following command in the terminal:
		
		flutter devices

4. It is highly recommended to run the application in emulator. So start an emulator from the Android studio.

5. After the emulator starts, run the following command in the VSCode terminal to run the application:
		
		flutter run

6. If you want to run the application on web browser, write the following command in the VSCode terminal:
		
		flutter run -d chrome

This should run the application on Emulator or Web browser based on the command you give.

IMPORTANT:
1. In order to interact with the frontend application, make sure the Backend and Ollama server is running.

2. If the LLM response is very slow, there is a high chance you forgot to run the LLM in Ollama. Follow step 6 of Ollama instructions to get quick response. 

3. Ideally, if the backend server is running, your application should get connected to it. But if your application fails to connect to backend server, you
might need to change the baseUrl to connect to the backend server as follows:

	 i. Go to lib --> services --> api_service
        ii. Go to line no. 29 and update the baseUrl variable with the address at which the backend server is running.
       iii. Restart the application using the command given in step 5 or 6 in the instructions section.



 ----------------------------------------------------------------------------
|			  RAG Implementation  			             |
 ----------------------------------------------------------------------------
Instructions for running and testing the RAG implementation:

1. Make sure Python 3.13.1 or greater is installed.

2. Make sure Ollama is running the Llama 3.2 in the backend if you want to get quick response.

3. Open the Backend folder from VSCode.

4. Open a terminal, create and activate a virtual environment using the following commands:
	Create venv: python -m venv venv

	Activate venv: 
		for windows: venv\Scripts\activate
		for macOS/Linux: source venv/bin/activate

5. After activating the venv, make sure PIP is installed. If PIP is not installed, use the following command to install it:
		for windows: py -m pip install --upgrade pip setuptools wheel
		for macOS/Linux: python3 -m pip install --upgrade pip setuptools wheel
		
6. Then install the required libraries from requirements.txt file using the following command:
				
		pip install -r requirements.txt

7. To create the ChromaDB vector database, uncomment line no. 187. The line should look like this:

		process_and_store_pdfs_in_directory("./data")

8. After that write the following command in the terminal:

		python app.py

  This should read all of the PDFs from the data folder and create a vectorized DB. You should see a chromaDB folder appearing in the file structure.
  You might encounter a numpy error as ChromaDB and langchain-community have some compatibility issues with numpy versions. In that write the following commands:

				pip uninstall numpy
				pip install numpy

  If might give you a warning about conflicting compatibility. Just ignore it. Now you should be able to run the app.py file successfully.


9. To test the LLM response, comment the line no. 187 that you uncommented in the last step. Now comment line no. 190-194. The lines should look like this:

		prompt = "What is the minimum IELTS score required for MSc application?"
		top_10_context, corresponding_metadata = query_collection(prompt)
		top_3_documents = re_rank_cross_encoders(top_10_context, corresponding_metadata, prompt)

		print(call_llm(top_3_documents, prompt))
   
   You can change the prompt to your liking.

10. After that write the following command in the terminal:

		python app.py
		

This should give you the Llama 3.2 response based on the fetched context in the terminal.

		