# Simulated-RCT-Generative-AI-Can-Harm-Learning
Simulate the randomized control trial (RCT) conducted by the Wharton School in 2024: Generative AI Can Harm Learning: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4895486. 

## Abstract
Generative artificial intelligence (AI) is poised to revolutionize how humans work, and has already demonstrated promise in significantly improving human productivity. However, a key remaining question is how generative AI affects learning, namely, how humans acquire new skills as they perform tasks. This kind of skill learning is critical to long-term productivity gains, especially in domains where generative AI is fallible and human experts must check its outputs. We study the impact of generative AI, specifically OpenAI's GPT-4, on human learning in the context of math classes at a high school. In a field experiment involving nearly a thousand students, we have deployed and evaluated two GPT based tutors, one that mimics a standard ChatGPT interface (called GPT Base) and one with prompts designed to safeguard learning (called GPT Tutor). These tutors comprise about 15% of the curriculum in each of three grades. Consistent with prior work, our results show that access to GPT-4 significantly improves performance (48% improvement for GPT Base and 127% for GPT Tutor). However, we additionally find that when access is subsequently taken away, students actually perform worse than those who never had access (17% reduction for GPT Base). That is, access to GPT-4 can harm educational outcomes. These negative learning effects are largely mitigated by the safeguards included in GPT Tutor. Our results suggest that students attempt to use GPT-4 as a "crutch" during practice problem sessions, and when successful, perform worse on their own. Thus, to maintain long-term productivity, we must be cautious when deploying generative AI to ensure humans continue to learn critical skills.

\* *HB, OB, and AS contributed equally*

## Steps to Simulate the Experiment
1. Run Pre-Experiment A/A analysis to check for existing differences and variance of key experiment metrics (scores).
Data was collected in three main ways. At the start of the study, students completed a survey capturing their demographics and educational background. During the sessions, student performance was recorded for both the assisted practice and the unassisted evaluations. Additionally, students who interacted with AI chatbots had their chat data logged, and surveys captured their experiences using the tools.
2. Randomly assign classrooms (C: no GPT, textbooks and notes only; T1: GPT-Base; T2: GPT-Tutor)
3. Simulate running the assisted and unassisted assessments on the classrooms.
4. Calculate scores for each group.
To evaluate the impact of the interventions, the authors used a regression model to analyze student outcomes. The dependent variable, Outcome(j) , represented the normalized grade of a student in either the assisted (j = 0) or unassisted (j = 1) sessions, scaled from 0 to 1. 
The independent variables GPTBasec and GPTTutorc indicate the treatment group for each class. The model controlled for prior student performance using normalized GPA from the previous year, PrevGPAi, and included fixed effects for session, grade, year, and time-related variations (θs, δg, αy, λt). Errors were clustered at the classroom level to account for correlations within groups.
5. Compare scores between classrooms using statistical tests and interpret the results.
Results indicate that use of the chatbots increased performance on the assisted assessment, with GPT Base improving scores by .137 (out of 1) and GPT Tutor improving scores by .361 (out of 1) relative to the control group. On the unassisted assessment, GPT Base decreased performance by .054 (out of one) relative to the control group (17% decrease). GPT Tutor’s impact on the unassisted portion was statistically significant at -.004. 
