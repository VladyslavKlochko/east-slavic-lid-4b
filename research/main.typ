#import "@preview/tracl:0.8.1": *
#import "@preview/pergamon:0.7.1": *

#show: doc => acl(doc,
  anonymous: false,
  title: [Can Small Language Models Distinguish Rusyn, Belarusian, and Ukrainian? An Empirical Study of Hallucination and Subsumption in Local 4B Language Models],
  authors: make-authors(
    (
      name: "Vladyslav Klochko",
      affiliation: [Varna University of Management \ Varna, Bulgaria \ #email("vladyslav.klochko@vum.bg")]
    ),
  ),
)

#abstract[
  Quantised 4B-parameter LLMs are usually marketed as an ideal choice for local tasks because of their multilinguality; however, some languages still remain poorly understood. In this research, three 4-bit (`Q4_K_M`) models are evaluated: Qwen3.5-4B, Ministral-3-3B-Instruct, and Nemotron-3.5-Bolt-E4B in four configurations on zero-shot language identification with proofs for Rusyn, Belarusian, and Ukrainian ($N = 15$ parallel sentences; $4 "configurations" times 15 "sentences" = 60$ deterministic runs). Results show Ministral invents grammatical rules to justify languages wrongly labelled as Russian, while Nemotron scores 5/5 on both Ukrainian and Belarusian, but 0/5 on Rusyn by mistaking its reflexive particle for Belarusian. Finally, enabling chain-of-thought (`<think>`) in Qwen3.5-4B triggers unclosed reasoning and repetition loops (0% compliance, 69.80s), whereas disabling it (`--reasoning-budget 0`) achieves 86.7% accuracy (80% on Rusyn) in 9.60s.
]

= Introduction

Language Identification (LID) is the first step in computer language tools used to sort, organise and send data to the relevant software @joulin2017fasttext. While modern LLMs accurately recognise and understand the context of widely spoken languages, identifying closely related languages remains challenging, especially when the alphabet and grammatical rules are similar @burchell2023openlid.

Three East Slavic languages - Rusyn, Belarusian, and Ukrainian - clearly show this problem. All three are written in the Cyrillic alphabet and share many rules; however, their online presence is very different. Ukrainian is well represented online, Belarusian has a much smaller online footprint, and Rusyn, being a stateless, endangered regional language mostly spoken in the Carpathian region, is almost completely missing from databases that are used to train modern AI models.

Today, small language models (3-4 billion parameters) @dettmers2023qlora can run offline, locally on ordinary laptops. However, being able to write perfect sentences does not mean the model understands how a language works. When small models encounter unfamiliar regional words or grammar, they rarely admit they do not know it. Instead, they tend to put minority languages in with larger neighbouring languages, a problem that is known as subsumption bias, or invent fake grammar rules to justify their wrong guesses.

This research evaluates three locally run models: Qwen3.5-4B, Ministral-3-3B-Instruct, and Nemotron-3.5-Bolt-E4B, using 15 sentences in Rusyn, Belarusian, and Ukrainian, 5 per each language.#footnote[Prompts and logs can be found at #link("https://github.com/vladyslavklochko/east-slavic-lid-4b").] The evaluation examines classification accuracy as well as the grammatical explanations the models generate to justify the choice. Comparing direct answers with chain-of-thought (CoT) reasoning reveals how bias toward a dominant language shapes predictions, and shows that turning on step-by-step reasoning for unfamiliar languages increases response time without raising accuracy.

= Related Work

Dedicated neural LID models such as fastText @joulin2017fasttext, OpenLID @burchell2023openlid, and GlotLID @kargaran2023glotlid achieve high accuracy on major languages, but their performance drops on closely related varieties and low-resource scripts. Shared tasks at VarDial, from the Discriminating Similar Languages (DSL) campaign @zampieri2014vardial to newer evaluations @aepli2023vardial, show that separating mutually intelligible varieties and regional languages remains difficult. For Rusyn specifically, shared Cyrillic characters and regional spelling differences require dedicated lexical and grammatical resources to avoid confusion with Ukrainian or Russian @rabus2017rusyn.

In generative natural language processing (NLP), @blevins2022contamination show that imbalances in pretraining data pull multilingual models toward dominant high-resource languages. Furthermore, @ji2023hallucination find that language models often produce false explanations after choosing an answer, while @turpin2023unfaithful show that CoT traces frequently justify biased guesses instead of reflecting real reasoning. Greedy decoding (`temp = 0`) can also trigger token-repetition loops on unfamiliar inputs @holtzman2020curious. The present study examines how these problems affect quantised local 4B models on East Slavic languages.

= Methodology

== East Slavic Diagnostic Dataset

To prevent models from relying on memorised training examples or place names, a diagnostic dataset of 15 parallel sentences was created, divided evenly across Ukrainian (`U1`-`U5`), Belarusian (`B1`-`B5`), and Prešov-standard Rusyn (`R1`-`R5`). The Prešov standard is used because it has been officially codified since 1995 with a fixed Cyrillic orthography, avoiding ambiguity from uncodified regional spellings. The sentences form five parallel triples (`U1-B1-R1` through `U5-B5-R5`) that express the same meaning across five everyday topics while testing specific words and grammar markers:

- *Triple 1 (Weather and Nature)*: Early autumn frost without geographical names (such as the Carpathians), comparing time adverbs ("цьогоріч" / "сёлета" / "того року"), intensifiers ("надто" / "занадта" / "барз"), and words for frost ("іній" / "шэрань" / "мразок").
- *Triple 2 (Work and Speech)*: Avoiding idle talk, excluding shared loanwords (such as "проєкт" / "праект") in favour of native phrases ("марні балачки" / "пустыя размовы" / "даремну бесіду") and attached versus separate reflexive particles ("взятися" / "ўзяцца" / "взяти ся").
- *Triple 3 (Urban Space and Motion)*: Closing a small gate and walking down a narrow street to a railway station, testing three distinct words for "gate" ("хвіртку" / "брамку" / "фіртку") and comparing "вокзалу" / "вакзала" against the Rusyn borrowing "штації".
- *Triple 4 (False Friends and Modality)*: Recalling a Sunday agreement, using the inter-Slavic false friend "неділя" / "нядзеля" ("Sunday", which looks like Russian "неделя" "week") together with dative pronouns ("мені здається" / "мне здаецца" / "ми ся видить") and degree adverbs ("трохи" / "крыху" / "дакус").
- *Triple 5 (Civic Event and Cultural Terms)*: Street musicians near a town hall, comparing "майдані" and "містян" (Ukrainian), "плошчы" and "гараджан" (Belarusian), and the Rusyn words "вароському ринку" ("town market"), "обы" ("in order to"), and "гудаків" ("musicians/fiddlers").

Every sentence is tested zero-shot with the same prompt:
#quote(block: true)[
  `Task: Identify the language of the provided text and explain briefly (1 sentence) which specific words or grammatical features helped you decide. Choose strictly from: [Ukrainian, Belarusian, Rusyn, Russian, Other].`
]
`Russian` is included as a high-resource East Slavic option to measure subsumption bias, and `Other` allows the model to abstain.

== Models and Inference Setup

Three 4-bit quantised (`Q4_K_M`, @dettmers2023qlora) GGUF models are evaluated across four configurations:
1. *Ministral-3-3B-Instruct-2512* (`Direct`, `mistralai/Ministral-3-3B-Instruct-2512-GGUF`): A standard instruction-tuned model without reasoning tags.
2. *Qwen3.5-4B* (`No-Think` vs. `Thinking`, `bartowski/Qwen_Qwen3.5-4B-GGUF`): Tested both with reasoning turned off (`--reasoning-budget 0`) and with default `[Start thinking]` reasoning enabled.
3. *NVIDIA Nemotron-3.5-Bolt-E4B* (`CoT`, `nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-4GB`): A reasoning model whose built-in `llama.cpp` chat template ignores `--reasoning-budget 0` and outputs `[Start thinking]` blocks on every run; it is tested in its default CoT mode.

All 60 runs were executed locally via `llama-cli` on an NVIDIA GeForce RTX 4060 laptop GPU (`-ngl 99`) using greedy decoding (`--temp 0`, `-s 42`), an 8,192-token context window (`-c 8192`), and a hard output limit of `max_tokens = 4096` (`-n 4096`).

== Error Categories

Based on manual inspection of all 60 outputs, model errors fall into three categories:
- *Subsumption Bias*: Assigning a low-resource language to a larger neighbouring language, either as *Russocentric subsumption* (labelling Ukrainian, Belarusian, or Rusyn as `Russian`) or *national-standard collapse* (labelling `Rusyn` as `Ukrainian` or `Belarusian`).
- *Grammatical Fabrication*: Writing explanations that invent false grammar rules or mistranslate words to justify a wrong label @ji2023hallucination.
- *Reasoning Trap (`<think>` Degeneration)*: Running out of the 4,096-token budget inside an unclosed `[Start thinking]` block due to circular self-questioning or token-repetition loops @holtzman2020curious.

= Results and Error Analysis

@tab:results lists classification accuracy per language, format compliance (closing any reasoning block and producing a valid answer within 4,096 tokens), and average response time across the 15 test sentences.

#figure(
  placement: top,
  scope: "parent",
  {
    set text(size: 8.5pt)
    table(
      columns: (auto, auto, auto, auto, auto, auto, auto),
      align: (left, center, center, center, center, center, center),
      stroke: 0.5pt,
      [*Model (Configuration)*], [*Ukr.*], [*Bel.*], [*Rus.*], [*Overall*], [*Format*], [*Mean Latency*],
      [Ministral-3-3B (Direct)], [1/5], [2/5], [2/5], [33.3%], [100%], [5.76s],
      [Qwen3.5-4B (No-Think)], [*5/5*], [4/5], [*4/5*], [*86.7%*], [100%], [9.60s],
      [Qwen3.5-4B (Thinking)#super[\*]], [5/5], [*5/5*], [3/5], [86.7%], [0%], [69.80s],
      [Nemotron-3.5-Bolt-E4B (CoT)], [*5/5*], [*5/5*], [0/5], [66.7%], [100%], [18.81s],
    )
  },
  caption: [Zero-shot East Slavic LID accuracy, format compliance, and mean latency (`ctx = 8192`, `max_tokens = 4096`, `temp = 0`). #super[\*]With CoT enabled, Qwen3.5-4B never closed its `[Start thinking]` block within 4,096 tokens; accuracy reflects latent answers inside unclosed traces (which suffered 3 token-repetition loops on `U2`, `R1`, and `R3`).]
) <tab:results>

== Russocentric Subsumption in Ministral-3-3B

*Ministral-3-3B* reaches 33.3% accuracy (5/15), and *9 of its 10 errors assign the label `Russian`* (4/5 Ukrainian, 3/5 Belarusian, and 3/5 Rusyn). Instead of selecting `Other`, the model invents grammatical rules to justify classifying East Slavic sentences as Russian:
- *Treating native words as borrowings*: On Ukrainian `U4` ("Мені здається, що минулої неділі ти трохи забув про нашу домовленість"), Ministral translates "неділя" as "Sunday" but calls it a loanword, stating that *"the verb 'забув' is Russian"* and *"домовленість (agreement) is also a Russian term"*. On `U3`, it labels the sentence Russian while calling "хвіртка" ("gate") *"regional influence"*.
- *Invented morphology*: On Belarusian `B1`, Ministral claims that the prosthetic *v-* in "восень" ("autumn") and the ending *-aj* in "раніцай" follow standard Russian grammar. On `B3`, it cites the Belarusian non-syllabic *-ў* in "зачыніў" as a Russian feature.
- *Misreading separate reflexive particles*: On Rusyn `R2`, Ministral calls the Prešov Rusyn reflexive "взяти ся" a *"Russian colloquial form of взяться"* and states that the sentence lacks Cyrillic letters typical of Ukrainian, Belarusian, or Rusyn, ignoring the `і` in "бесіду" and "ліпше".

== National-Standard Collapse in Nemotron-3.5-Bolt-E4B

*Nemotron-3.5-Bolt-E4B* separates the two national languages accurately, scoring *100% on Ukrainian (5/5) and Belarusian (5/5)* at 18.81s per query. On Rusyn, however, it scores *0% (0/5)*, assigning the sentences to Belarusian (`R1`, `R4`, `R5`) or Ukrainian (`R2`, `R3`).

Its reasoning traces show three recurring errors:
1. *Classification error*: In `R2` and `B5`, Nemotron explicitly defines Rusyn as a *"West Slavic language"*. Seeing East Slavic word order and Cyrillic script, it rules out Rusyn immediately and chooses between Ukrainian and Belarusian.
2. *Single-letter over-generalisation*: On Rusyn `R3` ("Він скоро запер фіртку..."), Nemotron relies on the letter `і` in "фіртку" and "улицю" to predict Ukrainian, ignoring Rusyn words like "штації" and the hard adjective ending "узку". On `R1`, `R4`, and `R5`, it treats `ы` ("першый", "ты") and the separate reflexive particle "ся" ("зобрало ся") as exclusively Belarusian.
3. *Phonetic guessing*: On Rusyn `R5`, Nemotron guesses unfamiliar cultural words by sound similarity to Russian, translating "гудаків" ("street musicians/fiddlers") as `'bells/chimes'` (by confusion with Russian "гудок", "horn/chime") and labelling the text Belarusian.

== Reasoning Traps in Qwen3.5-4B

Comparing *Qwen3.5-4B* with and without CoT shows that extra reasoning tokens make the model less reliable on this task, similar to prior findings on unfaithful reasoning traces @turpin2023unfaithful. In `Thinking` mode, Qwen3.5-4B fails to close its `[Start thinking]` block on all 15 sentences (*0% format compliance*, 69.80s average latency) for two main reasons:
- *Prompt-constraint loops*: Even after finding the right language within the first 250 tokens (latent scores of 5/5 Ukrainian, 5/5 Belarusian, and 3/5 Rusyn), the model spends thousands of tokens debating whether `"Ukrainian. The text is..."` breaks the `"1 sentence"` rule in the prompt.
- *Greedy token-repetition loops*: As observed in prior work on text degeneration under greedy decoding @holtzman2020curious, unfamiliar words trigger exact phrase loops inside the trace under `temp = 0`. On Ukrainian `U2` ("гаяти"), Qwen repeats `'Belarusian is "гавіць" is not right.'` over 280 times; on Rusyn `R3` ("запер"), it repeats `'зупинив is past tense. зупинився is past tense.'` over 300 times until truncation; on `R1`, it repeats its word-by-word breakdown until hitting the 4,096-token limit.

Turning off CoT (`--reasoning-budget 0`, `No-Think`) removes both problems. `Qwen3.5-4B (No-Think)` reaches *100% format compliance*, runs *$7.3 times$ faster* (9.60s), and achieves the highest accuracy at *86.7% (13/15)*, including *4/5 (80%) on Rusyn* (`R2`-`R5`). It correctly identifies Rusyn markers such as "фіртку", "желізничной", "вароському", and "зобрало ся". Its only Belarusian error (`B1`) goes in the opposite direction of subsumption, classifying Belarusian "Сёлета ... шэрань" as `Rusyn`.

= Conclusion

Across these East Slavic tests, quantised 4B local models fail in distinct ways. *Ministral-3-3B-Instruct* assigns most inputs to Russian (33.3% accuracy) using invented grammatical rules. *Nemotron-3.5-Bolt-E4B* identifies Ukrainian and Belarusian accurately (100%) but fails on stateless Rusyn (0/5). In *Qwen3.5-4B*, unconstrained CoT causes unclosed reasoning blocks and repetition loops, whereas disabling reasoning (`No-Think`) reaches 86.7% overall accuracy and 80% on Rusyn at 9.60s per query.

Upcoming studies will expand this evaluation to other low-resource European language groups, including regional Romance and Celtic varieties, using larger multi-sentence datasets. Future work will also compare larger model scales (7B-14B parameters) and test lightweight LoRA fine-tuning @dettmers2023qlora to reduce subsumption bias in local language tools.

#heading(numbering: none)[Limitations]

This diagnostic dataset is intentionally small ($N = 15$ sentences, 60 runs) so that every reasoning trace could be inspected manually, which limits statistical generalisation across broader text genres. In addition, the Rusyn sentences follow the Prešov standard and do not test Pannonian or Lemko varieties. Finally, all experiments used greedy decoding (`temp = 0`) and 4-bit quantisation (`Q4_K_M`); non-zero sampling temperatures (`temp = 0.6`), unquantised weights (`FP16`), or task-specific LoRA fine-tuning may reduce repetition loops in reasoning models.

#bibliography("references.bib")