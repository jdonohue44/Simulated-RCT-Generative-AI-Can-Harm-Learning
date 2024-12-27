# Simulated Randomized Control Trial (RCT): "Generative AI Can Harm Learning"

## About
In this report, we simulate a randomized control trial (RCT) conducted by the Wharton School in 2024, titled: “Generative AI Can Harm Learning” (https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4895486). Our simulation successfully reproduced the experiment results that having access to Chat GPT-4 improves student performance on math tests in the short term, but actually reduces performance when access to Chat GPT is taken away, suggesting that it hinders the long-term learning of new concepts. Conversely, using a customized Chat GPT-4 “Tutor” model boosted performance on assisted tasks without significantly affecting unassisted ones, indicating that purpose-built AI models may be a valuable tool for supporting long-term learning.

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
