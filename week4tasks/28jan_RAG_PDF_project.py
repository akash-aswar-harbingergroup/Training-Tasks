import os
import torch
import streamlit as st

from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings, HuggingFacePipeline
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import PromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser


st.set_page_config(
    page_title="PDF RAG Q&A",
    page_icon="📄",
    layout="wide"
)

st.title("📄 RAG-based PDF Question Answering")
st.caption("Powered by LangChain + FAISS + Qwen2 (Local LLM)")


os.environ["HF_HOME"] = "D:/huggingface_cache"
MODEL_ID = "Qwen/Qwen2-1.5B-Instruct"

@st.cache_resource(show_spinner=True)
def load_rag_pipeline(pdf_path: str):
    # 1. Load PDF
    loader = PyPDFLoader(pdf_path)
    documents = loader.load()

    # 2. Split into chunks
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200
    )
    docs = splitter.split_documents(documents)

    # 3. Embeddings + FAISS
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-mpnet-base-v2"
    )
    vector_db = FAISS.from_documents(docs, embeddings)
    retriever = vector_db.as_retriever(search_kwargs={"k": 4})

    # 4. Load Qwen model
    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)

    try:
        model = AutoModelForCausalLM.from_pretrained(
            MODEL_ID,
            dtype=torch.float32,
            device_map="cpu",
            low_cpu_mem_usage=True
        )
    except TypeError:
        model = AutoModelForCausalLM.from_pretrained(
            MODEL_ID,
            torch_dtype=torch.float32,
            device_map="cpu",
            low_cpu_mem_usage=True
        )

    hf_pipeline = pipeline(
        "text-generation",
        model=model,
        tokenizer=tokenizer,
        max_new_tokens=300,
        temperature=0.2,
        do_sample=False,
        return_full_text=False,
        eos_token_id=tokenizer.eos_token_id,
        pad_token_id=tokenizer.eos_token_id
    )

    llm = HuggingFacePipeline(pipeline=hf_pipeline)

    # 5. Prompt
    template = """
You are an AI assistant answering questions STRICTLY using the provided context.

RULES (MANDATORY):
1. Use ONLY information from the context.
2. If the answer is not present, reply EXACTLY with:
   "I don’t have enough information in the provided reference document."
3. Do NOT use external knowledge or assumptions.

CONTEXT:
{context}

QUESTION:
{question}

FINAL ANSWER:
"""
    prompt = PromptTemplate.from_template(template)

    def format_docs(docs):
        return "\n\n".join(d.page_content for d in docs)

    # 6. RAG Chain
    rag_chain = (
        {
            "context": retriever | format_docs,
            "question": RunnablePassthrough()
        }
        | prompt
        | llm
        | StrOutputParser()
    )

    return rag_chain, len(docs)

st.sidebar.header("📂 Document")
pdf_file = st.sidebar.text_input(
    "PDF file path",
    value="DPDP_Act_2023_Reference.pdf"
)

if "rag_chain" not in st.session_state:
    if st.sidebar.button("Load PDF"):
        with st.spinner("Loading PDF and building vector database..."):
            rag_chain, chunks = load_rag_pipeline(pdf_file)
            st.session_state.rag_chain = rag_chain
            st.session_state.chunks = chunks
            st.success(f"✅ Loaded {chunks} document chunks")

if "rag_chain" in st.session_state:
    st.subheader("💬 Ask a question")

    question = st.text_input(
        "Enter your question:",
        placeholder="e.g. What is DPDPA?"
    )

    if st.button("Ask"):
        if not question.strip():
            st.warning("Please enter a question.")
        else:
            with st.spinner("Searching document and generating answer..."):
                answer = st.session_state.rag_chain.invoke(question)

            st.markdown("### ✅ Answer")
            st.write(answer)

else:
    st.info("👈 Enter the PDF path and click **Load PDF** to begin.")