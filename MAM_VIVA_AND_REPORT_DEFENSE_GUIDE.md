# 🎓 AMRITA VISHWA VIDYAPEETHAM
## FUNDAMENTALS OF ARTIFICIAL INTELLIGENCE (23CSE401)
### VIVA DEFENSE & IMPLEMENTATION EXPLANATION DOSSIER
**Tailored Exactly to the Submitted Project Report**

- **Project Title:** AI-Based Movie Recommendation System Using TF-IDF and Cosine Similarity
- **Submitted by:** 
  1. L. Jahnavi Sai (AV.SC.U4CSE23024)
  2. M. Lakshmi Mahathi (AV.SC.U4CSE23052)
  3. K. Kumudini (AV.SC.U4CSE23053)
- **Branch & Section:** CSE-A | 7th Semester
- **Submitted to:** Dr. K Ashwini

---

# 📑 PART 1: HOW TO EXPLAIN THE FULL IMPLEMENTATION TO MAM
*(Deliver this 3-to-4 minute walkthrough confidently before she starts questioning you. This covers Sections 1 to 5 of your submitted report in logical order).*

### Step 1: The High-Level Objective (Page 3 of your report)
> *"Good morning, Ma'am. Our project is an AI-based, content-aware movie recommender system. With tens of thousands of movies on modern platforms, collaborative filtering suffers from the **user cold-start problem**—if a user has no previous watch history, the system cannot recommend anything.  
> To solve this, our system uses **Content-Based Filtering** based on the inherent attributes of the movies themselves, paired with live cloud enrichment from The Movie Database (TMDB) API."*

### Step 2: Offline Machine Learning Pipeline (Pages 5–8)
> *"Our implementation is divided into two major stages: **Offline Training** and **Online Request Serving**.*
>
> 1. **Dataset Cleaning (`movies.ipynb`)**:
>    - *We used the Kaggle 'The Movies Dataset' (`movies_metadata.csv`).*
>    - *We kept 6 core attributes: `title`, `overview`, `genres`, `tagline`, `vote_average`, and `popularity`.*
>    - *We dropped rows with missing titles, replaced missing overviews and taglines with empty strings, and parsed the stringified JSON genres into space-separated names.*
> 2. **Feature Engineering ('Tags')**:
>    - *We concatenated: $\text{tags} = \text{overview} + \text{genres} + \text{tagline}$.*
>    - *We normalized text using NLTK: lowercasing, removing non-alphabetic characters, removing English stop words, and applying the **WordNet Lemmatizer**.*
> 3. **TF-IDF Vectorization**:
>    - *We fitted scikit-learn's `TfidfVectorizer` with `max_features = 50,000`, `ngram_range = (1, 2)` (unigrams and bigrams), and $L_2$ normalization.*
>    - *This produced a **Compressed Sparse Row (CSR) matrix** of shape **45,447 rows $\times$ 50,000 columns**, containing **1,560,693 non-zero entries**—giving a matrix density of only **0.07%**.*
> 4. **Model Persistence**:
>    - *Because training on 45,000 movies takes time, we serialized the trained artifacts into 4 pickle files: `df.pkl`, `indices.pkl`, `tfidf_matrix.pkl`, and `tfidf.pkl`.*

### Step 3: Online Request Serving & Similarity Matching (Pages 6, 7 & 12)
> *"When our **FastAPI backend (`main.py`)** starts up:*
> 1. *It loads all four pickle files into RAM **once** inside its startup handler and creates a persistent asynchronous HTTP client (`httpx.AsyncClient`).*
> 2. *It builds a normalized lookup dictionary `TITLE_TO_IDX` (lowercased and whitespace-stripped).*
> 3. *When a user selects a movie at index `idx`, we compute its similarity against all 45,447 movies using **Cosine Similarity**:*
>    $$\text{scores} = \text{tfidf\_matrix} \times \text{tfidf\_matrix}[\text{idx}]^T$$
>    *Because scikit-learn $L_2$-normalizes the rows to unit length, cosine similarity is computed with a single sparse matrix-vector dot product.*
> 4. *We sort with `numpy.argsort`, skip the query movie itself (which scores 1.0), and retrieve the top-$N$ most similar titles."*

### Step 4: Hybrid Fallback & Frontend Delivery (Pages 6, 9 & 12)
> *"To ensure fault tolerance, our `/movie/search` bundle endpoint provides two complementary views:*
> 1. **TF-IDF Thematic Matches**: *Plot, genre, and tagline similarity from our local 45k catalog.*
> 2. **TMDB Genre Discover Matches**: *Live popular movies retrieved from TMDB's `/discover/movie` API using the query movie's first genre.*
>
> *If a user enters a newly released movie that isn't in our offline dataset, the local TF-IDF list gracefully returns empty while the TMDB genre recommendations still succeed.*
>
> *Finally, our **Streamlit frontend (`app.py`)** provides a responsive UI with real-time autocomplete search, category exploration (Trending, Popular, Top Rated), and a movie details view with high-res posters from TMDB's CDN."*

---

# 🔍 PART 2: PAGE-BY-PAGE QUESTIONS & MODEL ANSWERS (What Mam Will Ask From Your Document)

---

### 📄 SECTION 1: PROBLEM DEFINITION (Pages 3 – 4)

#### Q1.1: What is the formal specification of your nearest-neighbor problem? (Page 3, Table 1.3)
> **Answer:**  
> - **Item set ($M$):** $M = \{m_1, m_2, \dots, m_n\}$, the $n = 45,447$ cleaned movies.
> - **Item representation ($\mathbf{v}_i$):** A sparse TF-IDF vector $\mathbf{v}_i \in \mathbb{R}^{50,000}$ built from the preprocessed tags of movie $m_i$.
> - **Query ($q$):** A movie title $q$ that maps to a row index in the dataset.
> - **Similarity function:** $\text{sim}(q, m_i) = \cos(\mathbf{v}_q, \mathbf{v}_i) = \frac{\mathbf{v}_q \cdot \mathbf{v}_i}{\|\mathbf{v}_q\| \|\mathbf{v}_i\|}$.
> - **Output:** The top-$N$ items ranked by decreasing similarity, excluding $q$ itself.
> - **Auxiliary output:** Live details, posters, and popular movies from TMDB Discover for the first genre.

#### Q1.2: What are the explicit scope and constraints mentioned in your report? (Page 4, Section 1.5)
> **Answer:**
> 1. Recommendations rely strictly on **text** (overview, genres, tagline); no user ratings, cast, or director information is used.
> 2. The system is **non-personalized**: two users querying the same movie receive identical recommendations.
> 3. The local catalog is a **static snapshot** of Kaggle's "The Movies Dataset" (45,447 movies); newer titles only appear via TMDB live endpoints.
> 4. Poster and live detail retrieval require an **internet connection** and a valid TMDB API key.
> 5. English stop words and WordNet lemmatization are applied uniformly to all movies, including foreign-language titles.

---

### 📄 SECTION 2: METHODOLOGY & DESIGN APPROACH (Pages 5 – 7)

#### Q2.1: Why did you combine overview, genres, and tagline into 'tags'? Why not overview alone? (Page 5, Step 5)
> **Answer:**  
> A movie's plot overview alone often lacks explicit genre keywords. For example, the overview of an animated comedy might describe a toy lost in a room without using the words "animation" or "comedy". By concatenating $\text{tags} = \text{overview} + \text{genres} + \text{tagline}$, we inject explicit genre tokens and punchy marketing phrases, ensuring that shared genres and thematic taglines contribute heavily to the TF-IDF vector.

#### Q2.2: What specific NLP preprocessing steps did you apply to the tags? (Page 7, Table 2.4)
> **Answer:**  
> 1. **Lowercasing**: Treats "Space" and "space" as the exact same term.
> 2. **Removing non-alphabetic characters**: Drops punctuation, numbers, and symbols that introduce noise.
> 3. **Removing English stop words (NLTK)**: Eliminates non-discriminative words like "the", "and", "is".
> 4. **Lemmatization (WordNet)**: Reduces word variants to their root dictionary form (e.g., "movies" $\rightarrow$ "movie", "running" $\rightarrow$ "run").

#### Q2.3: Explain the sparsity and memory efficiency of your TF-IDF matrix. (Page 6, Section 2.3)
> **Answer:**  
> Our TF-IDF matrix has dimensions of $45,447 \text{ rows} \times 50,000 \text{ columns} = 2.27 \times 10^9$ potential cells.  
> However, only **1,560,693 entries are non-zero**, which is a density of just **0.07%** (meaning **99.93% of the cells are zeros**).  
> If stored as a dense array of 64-bit floats, it would consume:
> $$45,447 \times 50,000 \times 8 \text{ bytes} \approx 18.17 \text{ GB of RAM!}$$  
> Using SciPy's **Compressed Sparse Row (CSR)** matrix format, it takes **only about 19 MB on disk and RAM**, making it extremely lightweight and fast.

#### Q2.4: How does your code calculate Cosine Similarity in a single line? (Page 7, Section 2.5)
> **Answer:**  
> In `main.py` and `movies.ipynb`:
> ```python
> scores = tfidf_matrix @ tfidf_matrix[idx].T
> ```
> Because `TfidfVectorizer(norm='l2')` normalizes every row vector to unit length ($\|\mathbf{v}\|_2 = 1$), the denominator in cosine similarity $\frac{\mathbf{u} \cdot \mathbf{v}}{\|\mathbf{u}\|_2 \|\mathbf{v}\|_2}$ is $1 \times 1 = 1$. Therefore, cosine similarity is mathematically identical to the inner dot product!

---

### 📄 SECTION 3: DESCRIPTION OF ALGORITHMS USED (Pages 8 – 10)

#### Q3.1: Explain the mathematical formula for TF-IDF as stated in your report. (Page 8, Section 3.2.2)
> **Answer:**  
> $$\text{tf-idf}(t, d) = \text{tf}(t, d) \times \text{idf}(t)$$
> Where:
> - $\text{tf}(t, d)$ is the term frequency of term $t$ in document $d$.
> - Scikit-learn's smoothed inverse document frequency formula is:
>   $$\text{idf}(t) = \ln\left(\frac{1 + n}{1 + \text{df}(t)}\right) + 1$$
>   *(where $n$ is total documents $= 45,447$, and $\text{df}(t)$ is document frequency—how many documents contain term $t$. The $+1$ terms prevent division by zero and negative logs).*

#### Q3.2: Why did you set `ngram_range = (1, 2)`? (Page 8, Table 3.2.3)
> **Answer:**  
> Unigrams (single words) fail to capture two-word phrases where the context matters. For instance, "science fiction" would be broken into "science" and "fiction", and "serial killer" into "serial" and "killer". Bigrams preserve these two-word combinations as distinct features in the 50,000-word vocabulary.

#### Q3.3: What is the time and space complexity of your Cosine Similarity search? (Page 9, Table 3.3.3)
> **Answer:**  
> - **Time Complexity:** $\mathcal{O}(\text{nnz} + n \log n)$, where $\text{nnz} = 1,560,693$ (non-zero entries processed in the sparse dot product) and $n \log n$ represents sorting the $n = 45,447$ similarity scores using `numpy.argsort`.
> - **Space Complexity:** $\mathcal{O}(\text{nnz})$, storing only the non-zero sparse matrix entries (~19 MB in RAM).

#### Q3.4: How does the Genre-Based Recommendation (TMDB Discover) work? (Page 9, Section 3.4)
> **Answer:**  
> It takes the TMDB ID of the query movie, fetches its details from TMDB to identify its **first genre**, and queries TMDB's `/discover/movie` endpoint sorted by `popularity.desc`. It removes the query movie itself from the list and returns the remaining popular titles in that genre. This requires zero local model computation and works even for newly released films.

#### Q3.5: Compare TF-IDF + Cosine vs. Genre Discover. (Page 10, Table 3.5)
> **Answer:**  
> | Technique | Source | Strength | Limitation |
> | :--- | :--- | :--- | :--- |
> | **TF-IDF + Cosine** | Local dataset | Finds topically similar plots; fully explainable | Lexical/keyword-based; misses synonyms and deep semantic meaning |
> | **Genre Discover** | Live TMDB API | Always current; covers recent releases; adds serendipity | Coarser; uses only the first genre |
> | **Combined Bundle** | Both | Provides complementary thematic & popular views | Requires network access for TMDB components |

---

### 📄 SECTION 4: IMPLEMENTATION DETAILS (Pages 11 – 13)

#### Q4.1: What are the responsibilities of the files in your project structure? (Page 11, Table 4.2)
> **Answer:**  
> - `movies.ipynb`: Offline pipeline for data cleaning, text preprocessing, fitting the TF-IDF model, and exporting the pickle files.
> - `main.py`: FastAPI application hosting REST endpoints, TMDB client, and cosine ranking logic.
> - `df.pkl`: Cleaned DataFrame with 45,447 rows $\times$ 7 columns.
> - `indices.pkl`: Pandas Series mapping lowercased movie titles to row indices.
> - `tfidf_matrix.pkl`: Compressed sparse matrix ($45,447 \times 50,000$).
> - `tfidf.pkl`: Fitted `TfidfVectorizer` object.
> - `app.py`: Streamlit frontend consuming the FastAPI endpoints.
> - `.env`: Stores the `TMDB_API_KEY`.

#### Q4.2: How does Title Normalization work? (Page 12, Section 4.3.2)
> **Answer:**  
> When a title is received, it is stripped of leading/trailing whitespace and converted to lowercase:
> `_norm_title(t) = str(t).strip().lower()`  
> This ensures that `"Avatar"`, `"avatar"`, and `" AVATAR "` all map to the exact same row index in `TITLE_TO_IDX`. If a title is completely absent, it raises an HTTP 404 error.

#### Q4.3: How does the FastAPI backend ensure Safe TMDB Access? (Page 12, Section 4.3.3)
> **Answer:**  
> All TMDB requests pass through a centralized helper function `tmdb_get()`.  
> It uses a persistent `httpx.AsyncClient` with a 20-second timeout. Any network disconnects or non-200 responses are caught and wrapped into an HTTP 502 Bad Gateway with a descriptive error message, ensuring the server doesn't crash.

#### Q4.4: List all endpoints in your FastAPI API. (Page 12, Table 4.3.5)
> **Answer:**  
> 1. `GET /health` — Health check status.
> 2. `GET /home` — Curated TMDB feeds (`trending`, `popular`, `top_rated`, `upcoming`, `now_playing`).
> 3. `GET /tmdb/search` — Keyword movie search returning multiple matching cards.
> 4. `GET /movie/id/{tmdb_id}` — Detailed metadata, overview, genres, poster, and backdrop URLs.
> 5. `GET /recommend/genre` — Popular movies sharing the query movie's first genre.
> 6. `GET /recommend/tfidf` — Local TF-IDF recommendations with similarity scores.
> 7. `GET /movie/search` — Unified bundle endpoint: resolves title $\rightarrow$ details $\rightarrow$ TF-IDF recs with posters $\rightarrow$ genre recs.

---

### 📄 SECTION 5: RESULTS & ANALYSIS (Pages 14 – 16)

#### Q5.1: What are the exact experimental dataset statistics? (Page 14, Table 5.1)
> **Answer (Memorize these exact numbers!):**  
> - **Total movies:** $45,447$
> - **Matrix shape:** $45,447 \times 50,000$
> - **Non-zero entries:** $1,560,693$ (density: $\approx 0.07\%$)
> - **Average preprocessed text length:** $\approx 35$ words per movie (median: $31$, maximum: $150$)
> - **Movies with empty text after preprocessing:** $258$ ($\approx 0.6\%$)

#### Q5.2: What were your sample query results? (Page 14, Table 5.2)
> **Answer:**  
> | Query Movie | Top 1st Recommendation | Top 2nd Recommendation | Behavior |
> | :--- | :--- | :--- | :--- |
> | **Toy Story** | *Toy Story 3* (0.456) | *Toy Story 2* (0.412) | Franchise & sequel detection |
> | **The Dark Knight** | *The Dark Knight Rises* (0.309) | *Batman Forever* (0.249) | Character & world matching |
> | **Avatar** | *Avatar 2* (0.221) | *The Inhabited Island* (0.193) | Sci-Fi & alien ecosystem |
> | **Inception** | *Gamer* (0.195) | *Cypher* (0.178) | Mind-bending Sci-Fi thrillers |
> | **Titanic** | *Raise the Titanic* (0.170) | *The Tiger Brigades* (0.163) | Keyword sensitivity |

#### Q5.3: Why are the absolute cosine similarity scores relatively low (e.g., 0.15 to 0.46)? (Page 15, Section 5.3.4)
> **Answer:**  
> Because the vector space has **50,000 dimensions**. A typical movie overview has only about 35 words. Even when two movies share a theme, they only share a tiny fraction of the 50,000 dictionary terms. Therefore, **only the relative ranking matters, not the absolute magnitude of the score**.

#### Q5.4: What is "Keyword Sensitivity" or "Keyword Bias"? Give the Titanic example. (Page 15, Section 5.3.3)
> **Answer:**  
> TF-IDF is a lexical matching algorithm, not a deep semantic understanding model. For *Titanic*, the top recommendation is *Raise the Titanic* (score 0.170) and *Titanica* (0.153). These are adventure/documentary films about finding the ship wreckage, not romantic dramas like James Cameron's *Titanic*. They scored high simply because they share the rare, high-IDF keyword "Titanic". This shows why scores below $\approx 0.25$ should be considered weaker matches.

#### Q5.5: What was the query response time in your test environment? (Page 15, Section 5.3.5)
> **Answer:**  
> Computing the sparse vector product against all 45,447 movies and sorting the results takes roughly **0.8 to 1.0 second per query** in Python. Any additional latency in the bundle endpoint comes from looking up poster images on TMDB for each of the top-$N$ recommended titles.

---

### 📄 SECTION 6: CONCLUSION & FUTURE ENHANCEMENTS (Pages 17 – 18)

#### Q6.1: What are your key conclusions? (Page 17, Section 6.1)
> **Answer:**  
> 1. Content-based filtering provides effective recommendations without user history, solving the user cold-start problem.
> 2. Concatenating overview, genres, and taglines yields significantly richer signals than overview text alone.
> 3. TF-IDF with bigrams is fast, explainable, and excels at franchise and sequel detection.
> 4. Lexical matching has inherent limits: it cannot detect semantic synonyms (e.g., "cop" vs. "police officer").
> 5. Decoupled architecture with pickle persistence separates heavy training from fast online serving.

#### Q6.2: What future enhancements did you propose? (Pages 17 – 18, Section 6.2)
> **Answer:**  
> 1. **Semantic Embeddings:** Use Sentence-BERT (SBERT) to capture true semantic meaning and synonyms.
> 2. **Richer Features:** Incorporate cast, director, keywords, and production companies into the metadata soup.
> 3. **Hybrid Ranking:** Blend cosine similarity with `vote_average` and `popularity` to downrank obscure or poorly rated movies.
> 4. **Faster Retrieval:** Use `numpy.argpartition` for partial top-$K$ sorting instead of a full sort, or precompute nearest neighbors.
> 5. **Concurrent API Requests:** Fetch TMDB posters concurrently using `asyncio.gather()` rather than sequential requests.
> 6. **Fuzzy Title Matching:** Handle user typos in search using Levenshtein distance.
> 7. **Free-Text Search:** Allow users to type custom natural language queries (e.g., *"space movie with robots"*) and transform them into TF-IDF vectors using `tfidf.pkl`.

---

# ⚡ PART 3: RAPID-FIRE CHEAT SHEET (For Instant Confidence)

| If Mam Asks: | Instantly Answer: |
| :--- | :--- |
| **How many movies in total?** | **45,447** clean movies. |
| **TF-IDF Matrix Shape?** | **$45,447 \times 50,000$** |
| **Number of non-zero entries?** | **1,560,693** (density: **0.07%**). |
| **Why bigrams `(1, 2)`?** | To capture two-word phrases like *"science fiction"* or *"serial killer"*. |
| **What normalization?** | **$L_2$ Normalization** (unit vector length $= 1$). |
| **Why Cosine instead of Euclidean?** | Cosine measures vector angle, ignoring document length differences. |
| **What are the 4 pickle files?** | `df.pkl`, `indices.pkl`, `tfidf_matrix.pkl`, `tfidf.pkl`. |
| **What is the port for backend and frontend?** | Backend is **FastAPI on port 8000**; Frontend is **Streamlit on port 8501**. |
| **How do you handle Cold Start?** | Content-based filtering needs zero user watch history. New titles are handled via TMDB live genre discovery fallback. |
| **What is the main limitation?** | Lexical keyword matching can miss synonyms or over-rank incidental shared words (e.g., *Raise the Titanic* for *Titanic*). |

---
*Created specifically for the project viva of L. Jahnavi Sai, M. Lakshmi Mahathi, and K. Kumudini under Dr. K Ashwini.*