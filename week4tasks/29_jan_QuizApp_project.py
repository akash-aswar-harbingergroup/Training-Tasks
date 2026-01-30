import os
import torch
import streamlit as st
from transformers import pipeline, AutoTokenizer, AutoModelForCausalLM
from langchain_huggingface import HuggingFacePipeline
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser

# 1. Page Configuration
st.set_page_config(page_title="AI Quiz System", page_icon="❓")
st.title("AI-Powered Dynamic Quiz")

# 2. Initialize Model & Chain (Cached to prevent reloading on every click)
@st.cache_resource
def load_quiz_chain():
    os.environ["HF_HOME"] = "D:/huggingface_cache"
    model_id = "Qwen/Qwen2-1.5B-Instruct"
    
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    model = AutoModelForCausalLM.from_pretrained(
        model_id, 
        torch_dtype=torch.float32, 
        device_map={"": "cpu"},
        low_cpu_mem_usage=True
    )
    
    pipe = pipeline(
        "text-generation", 
        model=model, 
        tokenizer=tokenizer, 
        max_new_tokens=250,
        temperature=0.7,
        do_sample=True,
        return_full_text=False
    )
    
    llm = HuggingFacePipeline(pipeline=pipe)
    template = """<|im_start|>user
Generate 1 easy multiple choice question about {topic}.
Format the output exactly as follows:
Question: [Your question]
A) [Option 1]
B) [Option 2]
C) [Option 3]
D) [Option 4]
Correct Answer: [Letter Only]
<|im_end|>
<|im_start|>assistant
"""
    prompt = PromptTemplate.from_template(template)
    return prompt | llm | StrOutputParser()

chain = load_quiz_chain()

# 3. Initialize Session State for Tracking
if "total_que" not in st.session_state:
    st.session_state.update({
        "total_que": 0, "correct_ans": 0, "incorrect_ans": 0,
        "current_q": None, "current_a": None, "feedback": ""
    })

# Sidebar for Topic & Reset
with st.sidebar:
    topic = st.text_input("Enter Topic:", value="Python Basics")
    if st.button("Reset Score"):
        st.session_state.update({"total_que": 0, "correct_ans": 0, "incorrect_ans": 0})
    
    st.write(f"**Score: {st.session_state.correct_ans} / {st.session_state.total_que}**")

# 4. Quiz Logic
def generate_new_question():
    with st.spinner("Generating next question..."):
        raw_output = chain.invoke({"topic": topic})
        try:
            parts = raw_output.split("Correct Answer:")
            st.session_state.current_q = parts[0].strip()
            st.session_state.current_a = parts[1].strip()[:1].upper()
            st.session_state.feedback = "" # Clear previous feedback
        except:
            st.error("Error generating question. Please try again.")

# Button to start/next question
if st.button("Get Next Question") or st.session_state.current_q is None:
    generate_new_question()

# Display Question and Options
if st.session_state.current_q:
    st.markdown("---")
    st.markdown(st.session_state.current_q)
    
    with st.form("quiz_form"):
        user_choice = st.radio("Select your answer:", ["A", "B", "C", "D"], index=None)
        submitted = st.form_submit_button("Submit Answer")
        
        if submitted:
            if user_choice == st.session_state.current_a:
                st.session_state.feedback = "Correct! Well done."
                st.session_state.correct_ans += 1
            else:
                st.session_state.feedback = f"Wrong. The correct answer was {st.session_state.current_a}."
                st.session_state.incorrect_ans += 1
            st.session_state.total_que += 1

# Display Feedback
if st.session_state.feedback:
    st.info(st.session_state.feedback)
