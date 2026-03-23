# RAG, Chat with Docs и Память для ИИ-агентов
## Глубокое исследование · Март 2026

---

> **Область охвата:** Self-hosted, open-source инструменты и подходы для RAG, «Chat with Docs» и краткосрочной/долговременной памяти ИИ-агентов. Акцент на токен-эффективности, коммерческой применимости и Docker-совместимости.

---

## Содержание

1. [Введение и ключевые тренды](#1-введение-и-ключевые-тренды)
2. [Слой документов: парсинг и ингестия](#2-слой-документов-парсинг-и-ингестия)
3. [Векторные базы данных](#3-векторные-базы-данных)
4. [Модели эмбеддинга](#4-модели-эмбеддинга)
5. [Ранжирование и рериранк](#5-ранжирование-и-рериранк)
6. [RAG-фреймворки и оркестрация](#6-rag-фреймворки-и-оркестрация)
7. [GraphRAG и знаниевые графы](#7-graphrag-и-знаниевые-графы)
8. [Системы памяти для агентов](#8-системы-памяти-для-агентов)
9. [Chat with Docs: готовые платформы](#9-chat-with-docs-готовые-платформы)
10. [Хранилища данных и headless CMS](#10-хранилища-данных-и-headless-cms)
11. [Сравнительные таблицы](#11-сравнительные-таблицы)
12. [Рекомендуемые архитектуры](#12-рекомендуемые-архитектуры)
13. [Предлагаемый Docker Compose стек](#13-предлагаемый-docker-compose-стек)
14. [Выводы и рекомендации](#14-выводы-и-рекомендации)

---

## 1. Введение и ключевые тренды

### 1.1 Состояние рынка (март 2026)

RAG-экосистема прошла путь от «прикольного proof-of-concept» до фундаментальной инфраструктуры ИИ-приложений. Рынок RAG растёт с CAGR 44,7% до 2030 года. Ключевое изменение концепции: RAG превращается из паттерна «поиск + генерация» в **«Context Engine»** — унифицированную платформу сборки контекста для любых агентов.

### 1.2 Главные тренды 2025–2026

**Agentic RAG** — ИИ-агент сам решает, когда и что искать, итеративно уточняя запросы. Это уже не академический концепт, а production-паттерн.

**GraphRAG как стандарт** — Microsoft GraphRAG и его производные (LightRAG, Cognee) стали мейнстримом для задач, требующих многоуровневых связей между сущностями. Классический vector-only RAG проигрывает на вопросах, требующих обхода графа.

**Память как продукт** — Выделился отдельный класс инфраструктуры: системы агентной памяти (Mem0, Zep/Graphiti, Letta, LangMem). Вектор плюс граф плюс временна́я ось стали триадой современной памяти.

**Токен-эффективность** — Основной конкурентный параметр. Mem0 показывает 90%+ экономию токенов против full-context; LightRAG даёт 65–80% экономию против Microsoft GraphRAG при сопоставимом качестве.

**Hybrid Search** — BM25 + Dense Vector + Sparse Vector (SPLADE) + ColBERT reranking стали стандартной связкой. Одиночный vector search уже неконкурентоспособен.

**MCP и открытые API** — В 2025–2026 большинство серьёзных RAG-систем (RAGFlow, Dify, AnythingLLM) получили MCP-серверы или совместимые API, что делает их пригодными для кастомной интеграции.

---

## 2. Слой документов: парсинг и ингестия

### 2.1 Принцип «quality-in, quality-out»

Качество парсинга определяет 50–70% итогового качества RAG. Плохо извлечённые таблицы, потерянная структура заголовков, смешанные колонки — всё это напрямую снижает точность ретривала.

### 2.2 Инструменты парсинга

#### **Docling** (IBM Research / DS4SD)
- **Лицензия:** MIT (коммерческое использование — свободно)
- **Суть:** Open-source Python-библиотека. Использует DocLayNet для анализа разметки, TableFormer для структуры таблиц.
- **Форматы:** PDF, DOCX, PPTX, XLSX, HTML, изображения
- **Сильные стороны:** 97,9% точность на сложных таблицах (benchmark Procycons на корпоративных отчётах). Работает локально, не требует облака. Используется как парсер в RAGFlow и n8n-пайплайнах.
- **Слабые стороны:** Нет поддержки рукописного текста. Относительно медленный на больших документах.
- **Self-hosted:** Да (pip install, Docker-совместим)

#### **Unstructured.io**
- **Лицензия:** Apache 2.0 (open-source); Pro API — платная
- **Суть:** Комплексная платформа обработки любых форматов. OCR + NLP трансформеры.
- **Форматы:** PDF, DOCX, PPTX, HTML, Markdown, email, изображения, XML и 20+ других
- **Сильные стороны:** Лучшая поддержка OCR на scanned-документах. Широкий набор коннекторов (S3, GDrive, SharePoint). Признан лучшим по content fidelity на benchmark >1000 страниц enterprise-документов.
- **Слабые стороны:** Сложная настройка self-hosted. Open-source версия уступает API-версии.
- **Self-hosted:** Да (Docker, on-premise)

#### **MinerU** (Shanghai AI Lab)
- **Лицензия:** AGPL-3.0
- **Суть:** VLM-based парсер с акцентом на академические и технические документы (формулы, диаграммы).
- **Форматы:** PDF, изображения
- **Сильные стороны:** Превосходит Docling на документах с формулами и научными статьями. Поддержан RAGFlow с октября 2025.
- **Слабые стороны:** AGPL ограничивает коммерческое встраивание без раскрытия кода. Требует GPU для лучшего качества.
- **Self-hosted:** Да

#### **Marker**
- **Лицензия:** GPL-3.0 (open-source); есть платная версия без ограничений
- **Суть:** Быстрый PDF → Markdown конвертер. Использует surya OCR + нейронные детекторы структуры.
- **Форматы:** PDF
- **Сильные стороны:** Высокая скорость. Хорошее качество на современных PDF. Batch processing.
- **Слабые стороны:** GPL-ограничения; слабее на scanned-документах.
- **Self-hosted:** Да

#### **LlamaParse** (LlamaIndex)
- **Лицензия:** Проприетарный SaaS; есть бесплатный tier
- **Суть:** Cloud-first парсер от команды LlamaIndex. Мощный на сложных layouts.
- **Форматы:** PDF, DOCX, PPTX, XLSX, HTML, изображения
- **Сильные стороны:** Очень хорошее качество на сложных layouts; простая интеграция с LlamaIndex.
- **Слабые стороны:** Не self-hosted. Платный для продакшна.

### 2.3 Выбор парсера

| Критерий | Рекомендация |
|---|---|
| Коммерческий self-hosted, таблицы | **Docling** |
| Максимальное качество OCR, scanned | **Unstructured (open-source)** |
| Научные/технические документы | **MinerU** |
| Быстрый пайплайн PDF→Markdown | **Marker** |

---

## 3. Векторные базы данных

### 3.1 Архитектурные классы

**Специализированные векторные СУБД** (Qdrant, Milvus, Weaviate) — оптимизированы под HNSW и ANN-поиск. Логарифмическая сложность при миллиардах векторов.

**Расширения реляционных СУБД** (pgvector, Redis) — векторный поиск внутри привычных баз. Проще в эксплуатации, достаточны до 50–100M векторов.

**In-process / embedded** (ChromaDB, FAISS) — минимальная инфраструктура, ideal для прототипов.

### 3.2 Инструменты

#### **pgvector** (PostgreSQL extension)
- **Лицензия:** PostgreSQL License (MIT-совместимая, свободно коммерчески)
- **Суть:** Extension для PostgreSQL, добавляет тип `vector`, HNSW и IVFFlat индексы.
- **Производительность:** pgvectorscale достигает 471 QPS при 99% recall на 50M векторах. До 100M векторов — конкурентоспособен.
- **Сильные стороны:** Единая БД для реляционных и векторных данных. Полный SQL. Транзакции. Минимальные операционные расходы.
- **Слабые стороны:** При >100M векторов деградация. CPU-bound; без GPU-ускорения.
- **Использование в стеке:** База основного хранилища; векторный поиск для малых и средних коллекций.

#### **Qdrant**
- **Лицензия:** Apache 2.0 (полностью свободное коммерческое использование)
- **Суть:** Высокопроизводительный векторный поиск на Rust. Мощная фильтрация по payload.
- **Производительность:** Лидирует по RPS и latency на высокоразмерных эмбеддингах среди self-hosted. Поддерживает миллиарды векторов.
- **Сильные стороны:** Rust → низкий memory footprint. Богатая фильтрация (AND/OR/range по метаданным). gRPC + REST. Sparse vectors (SPLADE). Named vectors (несколько эмбеддингов в одной точке).
- **Слабые стороны:** Менее зрелый граф-layer по сравнению с Weaviate.
- **Использование в стеке:** Основной векторный движок для production RAG-систем.

#### **ChromaDB**
- **Лицензия:** Apache 2.0
- **Суть:** Lightweight, developer-friendly embedding database. Embedded или client-server режим.
- **Производительность:** CPU-bound; оптимален до 10–20M векторов.
- **Сильные стороны:** Минимальный порог входа (2 строки кода). Встроенные функции генерации эмбеддингов. Хорошо интегрирован с LangChain, LlamaIndex.
- **Слабые стороны:** Не production-grade при высоких нагрузках. Ограниченные возможности фильтрации.
- **Использование в стеке:** Прототипирование, dev-окружение, лёгкие production-нагрузки.

#### **Milvus**
- **Лицензия:** Apache 2.0
- **Суть:** Enterprise-grade векторная СУБД. GPU-ускорение. Горизонтальное масштабирование.
- **Производительность:** Лучшее время индексирования среди всех. GPU-accelerated search.
- **Сильные стороны:** Миллиарды векторов. Богатые типы индексов (IVF, HNSW, PQ, DiskANN). Kafka-интеграция. Kubernetes-native.
- **Слабые стороны:** Высокая операционная сложность. Избыточен для большинства команд.
- **Использование в стеке:** Enterprise с GPU и >100M векторов.

#### **Weaviate**
- **Лицензия:** BSD-3-Clause
- **Суть:** Семантическая поисковая система с знаниевым графом. GraphQL API.
- **Производительность:** Хорошая recall, но уступает Qdrant по RPS на high-dimensional задачах.
- **Сильные стороны:** Встроенная генерация эмбеддингов. Гибридный поиск. Knowledge graph. Multi-tenancy.
- **Слабые стороны:** Java-runtime → высокий RAM. Сложная операционная модель.
- **Использование в стеке:** Когда нужна knowledge graph интеграция внутри векторной СУБД.

#### **Neo4j**
- **Лицензия:** GPL-3.0 (Community); Enterprise — платный
- **Суть:** Лидирующая графовая СУБД. С версии 5.x — нативный vector search.
- **Сильные стороны:** Zрелый граф-движок. Cypher-запросы. Встроенный vector index. Идеален для GraphRAG.
- **Слабые стороны:** Community Edition имеет ограничения. GPL требует раскрытия при дистрибуции.
- **Использование в стеке:** GraphRAG, knowledge graphs, временна́я память агентов.

#### **Redis (Vector Search)**
- **Лицензия:** RSALv2 / SSPLv1 (с 2024; важно для коммерческого встраивания — использовать Valkey или Redis Stack ≤7.2)
- **Суть:** In-memory СУБД с модулем векторного поиска (RediSearch / VSS).
- **Производительность:** Очень высокий RPS за счёт in-memory. Но precision снижается при росте коллекции.
- **Сильные стороны:** Субмиллисекундная latency. Dual use: кеш + семантический поиск + сессионная память.
- **Использование в стеке:** Session memory, hot-cache эмбеддингов.

---

## 4. Модели эмбеддинга

### 4.1 Типы эмбеддингов

- **Dense** — один вектор, семантическое сходство. Основной тип.
- **Sparse (SPLADE/BM25)** — разреженный вектор, лексическое соответствие. Дополняет dense.
- **Multi-vector (ColBERT)** — вектор на каждый токен, поздняя интеракция. Высокая точность, высокие затраты памяти.
- **Hybrid** — комбинация dense + sparse в одной модели (BGE-M3).

### 4.2 Рекомендуемые модели (март 2026)

#### **BGE-M3** (BAAI)
- **Лицензия:** MIT (свободное коммерческое использование)
- **Параметры:** 568M
- **Context:** 8192 токенов
- **Уникальность:** Единственная open-source модель с unified dense + sparse + ColBERT в одной модели. 100+ языков.
- **MTEB:** 63.0 (multilingual). Лидер среди MIT-лицензированных.
- **Latency:** <30ms на H100 (batch=32)
- **Рекомендация:** **Основной выбор для production self-hosted RAG.** Особенно для гибридного поиска.

#### **Qwen3-Embedding-8B** (Alibaba)
- **Лицензия:** Apache 2.0 (коммерческое использование — свободно)
- **Параметры:** 8B
- **Context:** 32K токенов
- **MTEB:** 70.58 — топ-1 на MTEB multilingual leaderboard (февраль 2026)
- **Уникальность:** Instruction-aware. Настраиваемые размерности выхода (32–1024). Парная модель реранкинга Qwen3-Reranker-8B.
- **Latency:** ~200ms (большой размер — только с GPU)
- **Рекомендация:** Лучшее качество при наличии GPU; для двухстадийного поиска с Qwen3-Reranker-8B.

#### **Qwen3-Embedding-0.6B** (Alibaba)
- **Лицензия:** Apache 2.0
- **Параметры:** 0.6B
- **Context:** 32K токенов
- **Рекомендация:** Баланс скорость/качество; работает на CPU.

#### **nomic-embed-text-v1.5** (Nomic AI)
- **Лицензия:** Apache 2.0
- **Параметры:** 137M
- **Context:** 8192 токенов (matryoshka — можно сократить размерность)
- **Рекомендация:** Очень лёгкий, быстрый, хорошее качество для English. CPU-friendly.

#### **jina-embeddings-v3** (Jina AI)
- **Лицензия:** CC BY-NC 4.0 (некоммерческое; коммерческий тир платный)
- **Уникальность:** Multi-task LoRA адаптеры; задачи переключаются без смены модели.
- **Рекомендация:** Хорош для мультизадачных пайплайнов, но лицензия ограничивает коммерческое встраивание.

#### **all-MiniLM-L6-v2**
- **Лицензия:** Apache 2.0
- **Параметры:** 22M
- **Рекомендация:** Только для прототипирования. Архитектура 2019 года — уступает современным моделям по точности.

### 4.3 Сервинг эмбеддингов

| Инструмент | Лицензия | Описание |
|---|---|---|
| **Ollama** | MIT | Запуск embedding моделей локально. Поддерживает nomic-embed, bge-m3 |
| **TEI (HuggingFace Text Embeddings Inference)** | Apache 2.0 | Высокопроизводительный сервинг. Continuous batching. Flash Attention |
| **Infinity** | MIT | Быстрый сервер эмбеддингов с поддержкой sparse/dense/rerank |
| **Ollama** | MIT | Простой self-hosted запуск, широкая поддержка моделей |

---

## 5. Ранжирование и рериранк

Двухстадийный поиск: 1) быстрый ANN-поиск top-100 → 2) реранкинг до top-5 — это стандарт высококачественных RAG-систем.

### 5.1 Cross-Encoder реранкеры

| Модель | Лицензия | Параметры | Применение |
|---|---|---|---|
| **bge-reranker-v2-m3** (BAAI) | MIT | 568M | Лучший open-source реранкер общего назначения |
| **Qwen3-Reranker-8B** (Alibaba) | Apache 2.0 | 8B | Топ-1 по качеству; требует GPU |
| **ms-marco-MiniLM-L-6-v2** | Apache 2.0 | 22M | Быстрый, английский |

### 5.2 ColBERT (поздняя интеракция)

ColBERT хранит векторы на каждый токен документа и вычисляет MaxSim при запросе. Precision выше классических bi-encoder, но требует больше хранилища.

| Инструмент | Описание |
|---|---|
| **Ragatouille** | Python-библиотека для ColBERT-пайплайнов. Простой API. |
| **BGE-M3 ColBERT mode** | Встроенный ColBERT в BGE-M3 |
| **PLAID/ColBERT v2** | Оригинальная реализация Stanford |

---

## 6. RAG-фреймворки и оркестрация

### 6.1 Полный стек / End-to-End

#### **RAGFlow** (InfiniFlow)
- **Лицензия:** Apache 2.0
- **GitHub:** ~40k ★ (январь 2026)
- **Суть:** Полноценный RAG-движок с Deep Document Understanding (DeepDoc). Визуальный UI. REST API. Agentic workflow + MCP (с августа 2025). Memory для агентов (с декабря 2025).
- **Парсеры:** DeepDoc (собственный), MinerU, Docling (с октября 2025)
- **Индексирование:** Multi-path recall: BM25 + dense vector + знаниевый граф (TreeRAG). Fusion reranking.
- **Хранилища:** Elasticsearch / Infinity (поиск); MinIO (файлы); PostgreSQL (мета)
- **Сильные стороны:** Лучшая в классе обработка документов (таблицы, PDF со сложной разметкой, изображения внутри документов). Визуальный chunking с human-in-the-loop. GraphRAG. Готовый Docker Compose.
- **Слабые стороны:** Тяжёлый стек (требует Elasticsearch или Infinity). Полный образ 9GB.
- **Коммерция:** Apache 2.0, без ограничений на встраивание.
- **Self-hosted:** `docker compose up -d` из коробки.

#### **Dify** (LangGenius)
- **Лицензия:** Apache 2.0
- **GitHub:** ~80k ★
- **Суть:** Визуальная платформа для построения LLM-приложений. Workflow builder. Knowledge base с RAG. Agent builder. API deployment.
- **Сильные стороны:** Самый популярный open-source RAG+Agent builder по числу звёзд. Отличный UX. Multi-LLM. Встроенный PostgreSQL + Qdrant/Weaviate/Chroma для векторов.
- **Слабые стороны:** Монолитный стек, сложнее встраивать компоненты отдельно. Парсинг PDF уступает RAGFlow.
- **Self-hosted:** Docker Compose.

#### **R2R** (SciPhi)
- **Лицензия:** MIT
- **Суть:** Production-grade RAG-фреймворк. Hybrid search (BM25 + dense + reranking). GraphRAG. Knowledge graph. Multimodal.
- **Сильные стороны:** Отличная Python SDK. GraphRAG встроен. REST API для всего. Поддержка PDF, audio, video.
- **Слабые стороны:** Меньше UI по сравнению с Dify/RAGFlow.
- **Self-hosted:** Docker Compose (postgres profile).

#### **AnythingLLM** (Mintplex Labs)
- **Лицензия:** MIT
- **GitHub:** ~53k ★
- **Суть:** All-in-one LLM desktop + server. RAG из коробки. Workspace-based document isolation. No-code Agent builder с MCP.
- **Сильные стороны:** Лучший опыт для «chat with docs» без кода. RBAC для команд. Поддержка 30+ LLM провайдеров.
- **Слабые стороны:** Менее гибок как framework. Ограниченный API для кастомной интеграции.
- **Self-hosted:** Docker (1 команда).

### 6.2 Фреймворки-оркестраторы

#### **LangChain** + **LangGraph**
- **Лицензия:** MIT
- **Суть:** Самая большая экосистема LLM-разработки. LangGraph — stateful agent с памятью (LangMem).
- **Сильные стороны:** Огромная экосистема. Максимальная гибкость. Хорошая для кастомных пайплайнов.
- **Слабые стороны:** Высокий абстракционный overhead. Версионирование нестабильное.
- **Для RAG:** LCEL (LangChain Expression Language) + vector store retrievers.

#### **LlamaIndex**
- **Лицензия:** MIT
- **Суть:** Специализирован на ingestion, indexing, retrieval. Rich query engines. Graph indexes.
- **Сильные стороны:** Лучший для document-heavy задач. Богатые стратегии ретривала (fusion, tree, sub-question). Много коннекторов данных (100+).
- **Слабые стороны:** Более специализирован, меньше общего agent tooling.

#### **Haystack** (deepset)
- **Лицензия:** Apache 2.0
- **Суть:** Модульный production-grade фреймворк с explicit pipeline graphs.
- **Сильные стороны:** Явные, инспектируемые пайплайны. Встроенная оценка (RAGAs-совместимо). Хорошо для enterprise.
- **Слабые стороны:** Более многословный API, чем LangChain.

#### **Flowise**
- **Лицензия:** Apache 2.0
- **Суть:** No-code/low-code визуальный builder для LangChain-пайплайнов.
- **Сильные стороны:** Очень быстрый прототип. Docker self-hosted. Хорош для нетехнических пользователей.
- **Слабые стороны:** Ограничения при сложных custom-логиках.

#### **Cognee**
- **Лицензия:** Apache 2.0
- **Суть:** Cognitive memory layer. Строит knowledge graph из данных. Объединяет vector + graph retrieval.
- **Сильные стороны:** Композируемый GraphRAG. Несколько graph backends (NetworkX, FalkorDB, Neo4j). 30+ data source коннекторов.
- **Для стека:** GraphRAG + agent memory в одном инструменте.

### 6.3 Специализированные компоненты

| Инструмент | Лицензия | Назначение |
|---|---|---|
| **txtai** | Apache 2.0 | Embeddings DB + workflow engine в одном пакете |
| **DSPy** (Stanford) | MIT | Декларативная оптимизация RAG-пайплайнов. Программирование вместо промптинга |
| **RAGAs** | MIT | Автоматическая оценка RAG-пайплайнов (faithfulness, answer relevancy, context recall) |
| **FlashRAG** | MIT | Research: 36 RAG-алгоритмов из коробки для экспериментов |
| **Pathway** | BSL 1.1 | Real-time RAG с 350+ data source коннекторами |

---

## 7. GraphRAG и знаниевые графы

### 7.1 Зачем GraphRAG

Классический vector RAG проигрывает на:
- Вопросах, требующих связей между сущностями из разных документов
- Глобальном понимании тематики корпуса
- Временны́х и причинно-следственных запросах
- Multi-hop reasoning («через кого А связан с В?»)

Реальный пример: LinkedIn сократил время решения тикетов с 40 до 15 часов (−63%) внедрив GraphRAG.

### 7.2 Подходы и инструменты

#### **Microsoft GraphRAG**
- **Лицензия:** MIT
- **Суть:** Строит community summaries из корпуса. Local search (entity traversal) + Global search (community summaries).
- **Сильные стороны:** Наилучшее качество для глобальных/аналитических запросов. Хорошо задокументирован.
- **Слабые стороны:** Очень высокая стоимость индексирования (тысячи LLM-вызовов). Медленное обновление графа.
- **Лучший use case:** Аналитика статичных документальных корпусов.

#### **LightRAG**
- **Лицензия:** MIT
- **GitHub:** ~30k ★ (быстрый рост)
- **Суть:** Упрощённый graph RAG с dual-level retrieval (low-level: конкретные сущности; high-level: тематические концепции).
- **Сильные стороны:** 65–80% экономия токенов vs Microsoft GraphRAG при сопоставимой точности. Быстрая индексация. Инкрементные обновления.
- **Слабые стороны:** Менее мощный на глобальных запросах, чем полноценный GraphRAG.
- **Рекомендация:** **Лучший баланс стоимость/качество для GraphRAG**. Оптимален для 1500+ документов в месяц.

#### **Graphiti** (Zep)
- **Лицензия:** Apache 2.0
- **Суть:** Temporal knowledge graph. Сущности и отношения с временно́й осью (valid-from/to).
- **Сильные стороны:** Лучший для track-изменений-во-времени. Enterprise memory. Neo4j backend.
- **Слабые стороны:** Тяжёлый граф-construction; не для real-time (фоновая обработка занимает часы).

#### **FalkorDB**
- **Лицензия:** Server Side Public License (SSPL) / Redis-like
- **Суть:** Graph + Vector DB на основе RedisGraph. Sub-50ms queries.
- **Сильные стороны:** Очень высокая производительность граф-запросов. Хорошо с GraphRAG SDK.
- **Self-hosted:** Docker.

---

## 8. Системы памяти для агентов

### 8.1 Таксономия памяти

| Тип | Аналог | Инструменты |
|---|---|---|
| **Рабочая память** (context window) | RAM | LangChain ConversationBuffer, Redis session |
| **Эпизодическая** (конкретные события) | Дневник | Zep, Mem0 |
| **Семантическая** (факты/знания) | Энциклопедия | Mem0, LangMem |
| **Процедурная** (паттерны поведения) | Навыки | LangMem, Letta |
| **Архивная** (долговременная) | Жёсткий диск | Letta archival memory, Mem0 |

### 8.2 Ключевые системы

#### **Mem0**
- **Лицензия:** Apache 2.0 (self-hosted); Pro — SaaS
- **GitHub:** ~48k ★
- **Суть:** Наиболее популярный memory layer. Пассивная экстракция фактов из диалогов. Иерархия user/session/agent.
- **Производительность (LOCOMO):** 67,13% LLM-as-Judge; p95 latency 0,200s; ~1764 токена/разговор (экономия 90%+ vs full-context).
- **Сильные стороны:** 3 строки кода для интеграции. Framework-agnostic. Python + JS SDK. Versioned API. MMR reranking.
- **Слабые стороны:** При нагрузке — проблемы индексирования (память не добавляется стабильно). Граф-функции — только в Pro.
- **Архитектура:** Vector store (Qdrant/Chroma/pgvector) + optional graph (Neo4j). LLM для extraction.
- **Self-hosted:** pip install + конфигурация. Docker-совместим.

#### **Zep Community Edition** + **Graphiti**
- **Лицензия:** Apache 2.0 (Graphiti); Zep CE — ограниченный функционал
- **Суть:** Temporal knowledge graph. Точное моделирование «кто, что, когда». Episodic memory.
- **Производительность (LOCOMO):** Претендует на 75,14% (после коррекции конфигурации). Но: memory footprint >600k токенов/разговор. Фоновый граф-процессинг не позволяет real-time retrieval.
- **Сильные стороны:** Лучший для трекинга изменений во времени («кто был менеджером до марта?»).
- **Слабые стороны:** Дорогой граф-construction. Real-time retrieval ненадёжен сразу после ingestion.
- **Self-hosted:** Docker (Graphiti + Neo4j).

#### **Letta** (ex-MemGPT)
- **Лицензия:** Apache 2.0
- **Суть:** Полный agent runtime с OS-inspired memory. Core Memory (RAM) + Recall (disk cache) + Archival (cold storage). Агент сам управляет памятью через function calls.
- **Производительность:** ~83% на LongMemEval (оценка open-source систем).
- **Сильные стороны:** Агент явно редактирует свою память. Визуальный ADE (Agent Development Environment). Неограниченная архивная память. Полный контроль.
- **Слабые стороны:** Не drop-in memory layer — это полный agent runtime. Только Python SDK. Overhead на simple tasks.
- **Self-hosted:** Docker. REST API.

#### **LangMem** (LangChain)
- **Лицензия:** MIT
- **Суть:** Long-term memory layer для LangGraph. Semantic + episodic + procedural типы. Fact extraction + behavior memory.
- **Сильные стороны:** Нативная интеграция в LangGraph. Управляет конденсацией длинных историй.
- **Слабые стороны:** Тесно привязан к LangGraph. Не standalone.

#### **Hindsight** (Vectorize)
- **Лицензия:** MIT
- **Суть:** Новый (2025) memory layer с 4 стратегиями ретривала: semantic, graph, temporal, keyword.
- **Производительность:** 91,4% на LongMemEval — лучший результат среди open-source.
- **Сильные стороны:** Все 4 стратегии доступны даже в бесплатном self-hosted tier. MCP-compatible. Go SDK + Python.
- **Слабые стороны:** Относительно новый (~4k ★). Меньше экосистемы и tutorials.
- **Self-hosted:** `docker run -p 8723:8723 vectorize/hindsight`

#### **Cognee**
- **Лицензия:** Apache 2.0
- **Суть:** Knowledge graph-first memory. Строит полный граф из данных перед любыми запросами.
- **Сильные стороны:** Лучший для agentic систем накапливающих знания. Composable GraphRAG.
- **Self-hosted:** pip + Docker.

### 8.3 Краткая память (session/chat)

| Инструмент | Подход | Рекомендация |
|---|---|---|
| **Redis** | In-memory KV; TTL-based session | Стандарт для session memory. Быстро, просто |
| **PostgreSQL** | Persistent chat history | Для долговременного хранения истории |
| **LangChain Memory** | В памяти / Redis / PostgreSQL | Простые разговорные агенты |

---

## 9. Chat with Docs: готовые платформы

### 9.1 Обзор платформ

#### **Open WebUI**
- **Лицензия:** MIT (BSD-3-Clause)
- **GitHub:** ~124k ★
- **Суть:** ChatGPT-like интерфейс для Ollama и OpenAI-совместимых API. 282M+ Docker pulls.
- **RAG:** Встроенный RAG с 9 vector store backends (ChromaDB, pgvector, Qdrant, Milvus, Elasticsearch и др.). Knowledge bases с управлением документами.
- **Сильные стороны:** Largest community. Pipeline support. SSO/LDAP. Самый простой старт.
- **Слабые стороны:** RAG реализация менее зрелая, чем в AnythingLLM. Планируется рефакторинг.
- **Self-hosted:** Docker.

#### **AnythingLLM**
- **Лицензия:** MIT
- **GitHub:** ~53k ★
- **Суть:** Workspace-based document management. RAG as core feature. No-code agent flows с MCP.
- **Сильные стороны:** Лучший UX для enterprise document RAG. RBAC. Audit trail. 30+ LLM providers. Встроенный Agent с web browsing.
- **Слабые стороны:** Менее активная community vs Open WebUI.
- **Self-hosted:** Docker (`docker run mintplexlabs/anythingllm`).

#### **LibreChat**
- **Лицензия:** MIT
- **Суть:** Мульти-провайдерный чат (OpenAI, Anthropic, Google, Mistral и др.). Функционал форка чатов.
- **Сильные стороны:** Лучший для одновременной работы с несколькими LLM провайдерами.
- **Self-hosted:** Docker Compose.

#### **Khoj**
- **Лицензия:** AGPL-3.0
- **Суть:** Personal AI ассистент с интеграцией в Obsidian, Notion, Logseq. Deep Research mode.
- **Сильные стороны:** Лучший для «second brain» персонального использования. Scheduled automations.
- **Слабые стороны:** AGPL ограничивает коммерческое встраивание. Не enterprise.

#### **Danswer / Onyx**
- **Лицензия:** MIT
- **Суть:** Enterprise Q&A поверх корпоративных документов (Confluence, Jira, Google Drive, Slack).
- **Сильные стороны:** Богатые коннекторы к enterprise-инструментам. RBAC. Citation tracking.
- **Self-hosted:** Docker Compose.

---

## 10. Хранилища данных и headless CMS

Перечисленные инструменты могут входить в общий стек как источники данных для RAG и как сервисы управления контентом.

### 10.1 Реляционные СУБД

| Инструмент | Лицензия | Роль в стеке |
|---|---|---|
| **PostgreSQL + pgvector** | PostgreSQL License | Основная БД + векторный поиск |
| **Redis / Valkey** | MIT (Valkey) | Session memory, cache, pub/sub |

### 10.2 Headless CMS / No-code DB

#### **NocoDB**
- **Лицензия:** AGPL-3.0 (с Enterprise tier)
- **Суть:** Airtable-альтернатива на PostgreSQL/MySQL. REST + GraphQL API из любой таблицы.
- **В стеке:** UI управления knowledge base записями; источник структурированных данных для RAG.

#### **Teable**
- **Лицензия:** AGPL-3.0
- **Суть:** Более современная Airtable-альтернатива. Построена на PostgreSQL, Spreadsheet-like UI.
- **В стеке:** Управление structured content. Нативный PostgreSQL backend — прямой доступ.

#### **Directus**
- **Лицензия:** BSL 1.1 (производный код — под ограничениями при SaaS-распространении; self-hosted free)
- **Суть:** Headless CMS + Data Platform. Автоматический REST/GraphQL API из любой PostgreSQL схемы.
- **В стеке:** CMS для управления knowledge base документами с UI. API для ингестии в RAG.
- **Преимущество:** Работает поверх существующей PostgreSQL — не дублирует БД.

#### **Mem0 / Зep (Platform)**
- Уже описаны в разделе 8 — используются как memory store.

---

## 11. Сравнительные таблицы

### 11.1 Векторные базы данных

| Инструмент | Лицензия | Max Scale | Self-hosted | Hybrid Search | Граф | RAM | Коммерция |
|---|---|---|---|---|---|---|---|
| **pgvector** | PostgreSQL | ~100M | ✅ | BM25+dense (внешний) | ❌ | Низкий | ✅ Свободно |
| **Qdrant** | Apache 2.0 | Миллиарды | ✅ | ✅ (sparse+dense) | ❌ | Низкий (Rust) | ✅ Свободно |
| **ChromaDB** | Apache 2.0 | ~20M | ✅ | ❌ | ❌ | Средний | ✅ Свободно |
| **Milvus** | Apache 2.0 | Миллиарды+ | ✅ | ✅ | ❌ | Высокий | ✅ Свободно |
| **Weaviate** | BSD-3 | Миллиарды | ✅ | ✅ | ✅ | Высокий (Java) | ✅ Свободно |
| **Neo4j** | GPL-3.0 | Граф | ✅ (CE) | ✅ | ✅ | Средний | ⚠️ GPL ограничения |
| **Redis VSS** | RSALv2 | ~100M | ✅ (Valkey) | BM25+dense | ❌ | Высокий (in-mem) | ⚠️ Новая лицензия |

### 11.2 Модели эмбеддинга

| Модель | Лицензия | Параметры | MTEB | Context | Hybrid | Коммерция | CPU |
|---|---|---|---|---|---|---|---|
| **BGE-M3** | MIT | 568M | 63.0 | 8K | ✅ (d+s+c) | ✅ | ✅ |
| **Qwen3-Emb-8B** | Apache 2.0 | 8B | 70.58 | 32K | Dense | ✅ | ❌ |
| **Qwen3-Emb-0.6B** | Apache 2.0 | 0.6B | ~60 | 32K | Dense | ✅ | ✅ |
| **nomic-embed-v1.5** | Apache 2.0 | 137M | 62.4 | 8K | Dense | ✅ | ✅ |
| **jina-v3** | CC BY-NC | 570M | 65.1 | 8K | Dense | ⚠️ | ✅ |
| **all-MiniLM-L6-v2** | Apache 2.0 | 22M | ~57 | 512 | ❌ | ✅ | ✅ |

### 11.3 Системы памяти агентов

| Инструмент | Лицензия | Архитектура | LongMemEval | LOCOMO | Токен-эффект. | Self-hosted | Коммерция |
|---|---|---|---|---|---|---|---|
| **Mem0** | Apache 2.0 | Vector + opt.Graph | 49.0% | 67.13% | ✅✅ (−90%) | ✅ | ✅ |
| **Zep/Graphiti** | Apache 2.0 | Temporal Graph | н/д | 75.14%* | ⚠️ (600k+ токенов) | ✅ | ✅ |
| **Letta** | Apache 2.0 | OS-tiered Agent | ~83.2% | н/д | ✅ | ✅ | ✅ |
| **Hindsight** | MIT | 4-strategy retrieval | 91.4% | н/д | ✅ | ✅ | ✅ |
| **LangMem** | MIT | Structured store | н/д | н/д | ✅ | ✅ (через LG) | ✅ |
| **Cognee** | Apache 2.0 | KG-first | н/д | н/д | ✅ | ✅ | ✅ |

*Самооценка Zep после коррекции конфигурации.

### 11.4 RAG-фреймворки и платформы

| Инструмент | Лицензия | Тип | GraphRAG | Agent | MCP | UI | API | Docker |
|---|---|---|---|---|---|---|---|---|
| **RAGFlow** | Apache 2.0 | Engine | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Dify** | Apache 2.0 | Platform | ⚠️ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **R2R** | MIT | Framework | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **AnythingLLM** | MIT | Platform | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **LangChain** | MIT | Framework | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **LlamaIndex** | MIT | Framework | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Haystack** | Apache 2.0 | Framework | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Open WebUI** | MIT | UI+RAG | ❌ | ⚠️ | ⚠️ | ✅ | ✅ | ✅ |
| **Cognee** | Apache 2.0 | KG Memory | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |

### 11.5 Парсеры документов

| Инструмент | Лицензия | OCR | Таблицы | Формулы | Self-hosted | Коммерция |
|---|---|---|---|---|---|---|
| **Docling** | MIT | ✅ | ✅✅ (97.9%) | ⚠️ | ✅ | ✅ |
| **Unstructured OSS** | Apache 2.0 | ✅✅ | ✅ | ⚠️ | ✅ | ✅ |
| **MinerU** | AGPL-3.0 | ✅ | ✅ | ✅✅ | ✅ | ⚠️ |
| **Marker** | GPL-3.0 | ✅ | ✅ | ⚠️ | ✅ | ⚠️ |

---

## 12. Рекомендуемые архитектуры

### 12.1 Архитектура A: Минимальная (Прототип / Разработка)

**Цель:** Быстрый старт, минимум сервисов, всё работает на 8GB RAM.

```
┌─────────────────────────────────────┐
│           LLM (Ollama)              │
│     + nomic-embed / bge-m3           │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         AnythingLLM / Dify          │
│   (RAG pipeline + Chat UI)          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  PostgreSQL + pgvector + pgvectorscale │
│  (векторный поиск + реляционные данные) │
└─────────────────────────────────────┘
         + Redis (session memory)
```

**Стек:** PostgreSQL (pgvector), Redis, Ollama, AnythingLLM или Dify.
**RAM:** ~8–12 GB.
**Плюсы:** Простота, единая БД, минимальные зависимости.

---

### 12.2 Архитектура B: Стандартная Production (Рекомендуемая)

**Цель:** Полноценный production RAG + агентная память. Хорошее качество без избыточной сложности.

```
┌────────────────────────────────────────────────────┐
│                 INGESTION LAYER                    │
│   Docling / Unstructured → Chunking → Embedding   │
│            (BGE-M3 via TEI/Infinity)               │
└────────────────┬───────────────────────────────────┘
                 │
     ┌───────────▼─────────────────────────────────┐
     │            RETRIEVAL LAYER                   │
     │  ┌─────────────┐   ┌──────────────────────┐ │
     │  │   Qdrant    │   │  PostgreSQL+pgvector  │ │
     │  │(dense+sparse│   │  (metadata, relations)│ │
     │  │  векторы)   │   └──────────────────────┘ │
     │  └─────────────┘                             │
     │       + BM25 full-text (Elasticsearch/PG)    │
     │       + BGE Reranker (cross-encoder)         │
     └───────────────────┬─────────────────────────┘
                         │
     ┌───────────────────▼─────────────────────────┐
     │              MEMORY LAYER                    │
     │  ┌──────────────────┐  ┌──────────────────┐ │
     │  │   Mem0 (long-    │  │  Redis (session  │ │
     │  │   term agent mem)│  │  short-term mem) │ │
     │  └──────────────────┘  └──────────────────┘ │
     └───────────────────┬─────────────────────────┘
                         │
     ┌───────────────────▼─────────────────────────┐
     │           ORCHESTRATION LAYER                │
     │         LangChain / LlamaIndex / n8n         │
     │              AI Agent (LLM)                  │
     └───────────────────┬─────────────────────────┘
                         │
     ┌───────────────────▼─────────────────────────┐
     │              UI / API LAYER                  │
     │   Open WebUI / AnythingLLM / Custom API      │
     │        MCP Server (кастомные инструменты)    │
     └─────────────────────────────────────────────┘
```

**Сервисы:**
- PostgreSQL + pgvector (основная БД, история, мета, малые векторные коллекции)
- Qdrant (основной production vector store для больших коллекций)
- Redis (session memory, кеш)
- Mem0 (long-term agent memory)
- BGE-M3 via Infinity (embedding server)
- BGE-Reranker (reranking service)
- Docling (парсинг документов)
- n8n / LangChain (оркестрация)

---

### 12.3 Архитектура C: GraphRAG + Расширенная Память

**Цель:** Сложные аналитические запросы, multi-hop reasoning, трекинг изменений.

```
┌──────────────────────────────────────────────────┐
│                INGESTION                          │
│   Docling → LightRAG / Cognee                    │
│   → Entity Extraction (LLM)                      │
└─────────────────┬────────────────────────────────┘
                  │
    ┌─────────────▼─────────────────────────────┐
    │            STORAGE                         │
    │  ┌─────────┐  ┌──────────┐  ┌──────────┐ │
    │  │  Neo4j  │  │  Qdrant  │  │  Redis   │ │
    │  │(Knowledge│  │(Vectors) │  │(Session) │ │
    │  │  Graph) │  └──────────┘  └──────────┘ │
    │  └─────────┘                              │
    │  PostgreSQL (реляционные данные + мета)   │
    └─────────────┬─────────────────────────────┘
                  │
    ┌─────────────▼─────────────────────────────┐
    │            RETRIEVAL                       │
    │  Router: Vector Query vs Graph Traversal  │
    │  ↓                    ↓                   │
    │  Qdrant hybrid     Neo4j Cypher            │
    │  + BM25            + community summaries  │
    │  ↓────────────────────↓                   │
    │         Fusion Reranking                  │
    └─────────────┬─────────────────────────────┘
                  │
    ┌─────────────▼─────────────────────────────┐
    │            MEMORY                          │
    │  Zep/Graphiti (temporal KG для агента)    │
    │  Letta (если агент сам управляет памятью) │
    └─────────────┬─────────────────────────────┘
                  │
    ┌─────────────▼─────────────────────────────┐
    │       ORCHESTRATION + UI                   │
    │   LangGraph / n8n + LangMem               │
    │   RAGFlow / Dify (frontend)                │
    └────────────────────────────────────────────┘
```

---

### 12.4 Архитектура D: Максимальная (Полный Стек)

Включает все перечисленные компоненты. Предназначен для платформы, где нужны все возможности.

```
Инфраструктурный слой (shared):
  PostgreSQL (основная БД)  ← pgvector extension
  Redis / Valkey            ← session cache
  Neo4j                     ← knowledge graph

Специализированные векторные хранилища:
  Qdrant                    ← production RAG vectors
  ChromaDB                  ← dev/lightweight

Embedding & Reranking:
  Infinity / TEI            ← BGE-M3, Qwen3-Embedding
  BGE-Reranker-v2-m3        ← cross-encoder

Парсинг и ингестия:
  Docling                   ← PDF/DOCX/структурированные
  Unstructured               ← тяжёлые OCR задачи

RAG оркестрация:
  RAGFlow                   ← основной RAG engine + UI
  n8n                       ← workflow + MCP integration

Память агентов:
  Mem0                      ← long-term semantic memory
  Zep/Graphiti              ← temporal entity memory
  Redis                     ← short-term session memory

Headless CMS / Data:
  Directus                  ← CMS поверх PostgreSQL
  NocoDB                    ← no-code table UI
  Teable                    ← spreadsheet UI

Chat UI:
  Open WebUI                ← end-user interface
  AnythingLLM               ← enterprise document workspace

Кастомные компоненты:
  Custom API (FastAPI)      ← бизнес-логика, коннекторы
  MCP Server                ← инструменты для агентов
```

---

## 13. Предлагаемый Docker Compose стек

### 13.1 Структура файлов

```
memory-rag-stack/
├── docker-compose.yml           # Основной файл
├── docker-compose.graph.yml     # GraphRAG опции (Neo4j + LightRAG)
├── docker-compose.ui.yml        # UI-сервисы (Open WebUI, AnythingLLM)
├── docker-compose.cms.yml       # Headless CMS (Directus, NocoDB)
├── .env                         # Переменные окружения
└── configs/
    ├── postgres/init.sql        # pgvector + схемы
    ├── ragflow/service_conf.yml
    └── mem0/config.yaml
```

### 13.2 Базовый docker-compose.yml (Core Stack)

```yaml
# ============================================================
# MEMORY & RAG STACK — Core Services
# Март 2026 | Apache 2.0 / MIT компоненты
# ============================================================

version: "3.9"

x-restart: &default-restart
  restart: unless-stopped

x-logging: &default-logging
  logging:
    driver: "json-file"
    options:
      max-size: "50m"
      max-file: "3"

networks:
  rag-net:
    driver: bridge
    name: rag-net

volumes:
  postgres-data:
  redis-data:
  qdrant-data:
  chroma-data:
  minio-data:
  mem0-data:

services:

  # ─────────────────────────────────────
  # DATABASE LAYER
  # ─────────────────────────────────────

  postgres:
    <<: *default-restart
    <<: *default-logging
    image: pgvector/pgvector:pg16
    container_name: rag-postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-raguser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme}
      POSTGRES_DB: ${POSTGRES_DB:-ragdb}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./configs/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    networks:
      - rag-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-raguser}"]
      interval: 10s
      retries: 5

  redis:
    <<: *default-restart
    <<: *default-logging
    image: valkey/valkey:8-alpine   # MIT-лицензия (замена Redis 7.2)
    container_name: rag-redis
    command: valkey-server --save 60 1 --loglevel warning
    volumes:
      - redis-data:/data
    ports:
      - "${REDIS_PORT:-6379}:6379"
    networks:
      - rag-net

  # ─────────────────────────────────────
  # VECTOR STORE
  # ─────────────────────────────────────

  qdrant:
    <<: *default-restart
    <<: *default-logging
    image: qdrant/qdrant:v1.12.0
    container_name: rag-qdrant
    volumes:
      - qdrant-data:/qdrant/storage
    ports:
      - "${QDRANT_PORT:-6333}:6333"
      - "6334:6334"   # gRPC
    networks:
      - rag-net
    environment:
      QDRANT__SERVICE__API_KEY: ${QDRANT_API_KEY:-}

  chromadb:
    <<: *default-restart
    <<: *default-logging
    image: chromadb/chroma:0.6.0
    container_name: rag-chromadb
    volumes:
      - chroma-data:/chroma/chroma
    ports:
      - "${CHROMA_PORT:-8000}:8000"
    networks:
      - rag-net
    environment:
      CHROMA_SERVER_AUTH_CREDENTIALS: ${CHROMA_TOKEN:-changeme}
      CHROMA_SERVER_AUTH_PROVIDER: "chromadb.auth.token_authn.TokenAuthenticationServerProvider"

  # ─────────────────────────────────────
  # EMBEDDING SERVICE
  # ─────────────────────────────────────

  embedding:
    <<: *default-restart
    <<: *default-logging
    image: michaelf34/infinity:latest     # MIT-лицензия
    container_name: rag-embedding
    command: >
      v2
      --model-name-or-path BAAI/bge-m3
      --served-model-name bge-m3
      --port 7997
      --device cpu
    ports:
      - "${EMBED_PORT:-7997}:7997"
    networks:
      - rag-net
    volumes:
      - ./models:/app/.cache/huggingface

  reranker:
    <<: *default-restart
    <<: *default-logging
    image: michaelf34/infinity:latest
    container_name: rag-reranker
    command: >
      v2
      --model-name-or-path BAAI/bge-reranker-v2-m3
      --served-model-name bge-reranker-v2-m3
      --port 7998
      --device cpu
    ports:
      - "${RERANK_PORT:-7998}:7998"
    networks:
      - rag-net
    volumes:
      - ./models:/app/.cache/huggingface

  # ─────────────────────────────────────
  # OBJECT STORAGE (для документов)
  # ─────────────────────────────────────

  minio:
    <<: *default-restart
    <<: *default-logging
    image: minio/minio:latest
    container_name: rag-minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_USER:-minioadmin}
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD:-changeme}
    volumes:
      - minio-data:/data
    ports:
      - "${MINIO_PORT:-9000}:9000"
      - "9001:9001"
    networks:
      - rag-net

  # ─────────────────────────────────────
  # AGENT MEMORY LAYER
  # ─────────────────────────────────────

  mem0:
    <<: *default-restart
    <<: *default-logging
    image: mem0ai/mem0:latest
    container_name: rag-mem0
    volumes:
      - mem0-data:/mem0/data
      - ./configs/mem0/config.yaml:/mem0/config.yaml
    ports:
      - "${MEM0_PORT:-8080}:8080"
    networks:
      - rag-net
    depends_on:
      - postgres
      - qdrant
    environment:
      MEM0_CONFIG_PATH: /mem0/config.yaml

  # ─────────────────────────────────────
  # RAG ENGINE
  # ─────────────────────────────────────

  ragflow:
    <<: *default-restart
    <<: *default-logging
    image: infiniflow/ragflow:v0.24.0-slim
    container_name: rag-ragflow
    ports:
      - "${RAGFLOW_PORT:-80}:80"
      - "9380:9380"
    networks:
      - rag-net
    depends_on:
      - postgres
      - redis
      - minio
      - embedding
    environment:
      MYSQL_HOST: postgres
      MYSQL_PORT: 5432
      REDIS_HOST: redis
      MINIO_HOST: minio

  # ─────────────────────────────────────
  # DOCUMENT PARSER
  # ─────────────────────────────────────

  docling:
    <<: *default-restart
    <<: *default-logging
    image: quay.io/ds4sd/docling-serve:latest
    container_name: rag-docling
    ports:
      - "${DOCLING_PORT:-5001}:5001"
    networks:
      - rag-net
    environment:
      DOCLING_SERVE_LOG_LEVEL: INFO
```

### 13.3 Профиль: Graph (docker-compose.graph.yml)

```yaml
# Подключается как: docker compose -f docker-compose.yml -f docker-compose.graph.yml up -d

version: "3.9"

networks:
  rag-net:
    external: true

volumes:
  neo4j-data:
  lightrag-data:

services:

  neo4j:
    restart: unless-stopped
    image: neo4j:5.26-community
    container_name: rag-neo4j
    ports:
      - "${NEO4J_HTTP:-7474}:7474"
      - "${NEO4J_BOLT:-7687}:7687"
    environment:
      NEO4J_AUTH: ${NEO4J_USER:-neo4j}/${NEO4J_PASS:-changeme}
      NEO4J_PLUGINS: '["apoc", "graph-data-science"]'
      NEO4J_dbms_security_procedures_unrestricted: "apoc.*,gds.*"
    volumes:
      - neo4j-data:/data
    networks:
      - rag-net

  lightrag:
    restart: unless-stopped
    image: lightrag/lightrag-hku:latest
    container_name: rag-lightrag
    ports:
      - "${LIGHTRAG_PORT:-9621}:9621"
    volumes:
      - lightrag-data:/app/data
    networks:
      - rag-net
    environment:
      OPENAI_API_BASE: ${LLM_BASE_URL:-http://host.docker.internal:11434/v1}
      OPENAI_API_KEY: ${LLM_API_KEY:-ollama}
      EMBEDDING_FUNC_MAX_ASYNC: 4
```

### 13.4 Профиль: UI (docker-compose.ui.yml)

```yaml
version: "3.9"

networks:
  rag-net:
    external: true

volumes:
  openwebui-data:
  anythingllm-data:

services:

  open-webui:
    restart: unless-stopped
    image: ghcr.io/open-webui/open-webui:main
    container_name: rag-openwebui
    ports:
      - "${WEBUI_PORT:-3000}:8080"
    volumes:
      - openwebui-data:/app/backend/data
    networks:
      - rag-net
    environment:
      OLLAMA_BASE_URL: ${OLLAMA_URL:-http://host.docker.internal:11434}
      OPENAI_API_BASE_URL: ${OPENAI_BASE:-https://api.openai.com/v1}
      VECTOR_DB: qdrant
      QDRANT_URI: http://qdrant:6333
      RAG_EMBEDDING_ENGINE: openai
      RAG_EMBEDDING_MODEL: bge-m3
      RAG_OPENAI_API_BASE_URL: http://embedding:7997

  anythingllm:
    restart: unless-stopped
    image: mintplexlabs/anythingllm:latest
    container_name: rag-anythingllm
    ports:
      - "${ANYTHINGLLM_PORT:-3001}:3001"
    volumes:
      - anythingllm-data:/app/server/storage
    networks:
      - rag-net
    environment:
      VECTOR_DB: qdrant
      QDRANT_ENDPOINT: http://qdrant:6333
      EMBEDDING_BASE_PATH: http://embedding:7997/v1
      EMBEDDING_MODEL_PREF: bge-m3
```

### 13.5 Профиль: CMS (docker-compose.cms.yml)

```yaml
version: "3.9"

networks:
  rag-net:
    external: true

volumes:
  directus-uploads:
  nocodb-data:

services:

  directus:
    restart: unless-stopped
    image: directus/directus:11
    container_name: rag-directus
    ports:
      - "${DIRECTUS_PORT:-8055}:8055"
    volumes:
      - directus-uploads:/directus/uploads
    networks:
      - rag-net
    depends_on:
      - postgres
      - redis
    environment:
      SECRET: ${DIRECTUS_SECRET:-changeme-random-secret}
      DB_CLIENT: pg
      DB_HOST: postgres
      DB_PORT: 5432
      DB_DATABASE: ${DIRECTUS_DB:-directus}
      DB_USER: ${POSTGRES_USER:-raguser}
      DB_PASSWORD: ${POSTGRES_PASSWORD:-changeme}
      CACHE_ENABLED: "true"
      CACHE_STORE: redis
      REDIS_HOST: redis

  nocodb:
    restart: unless-stopped
    image: nocodb/nocodb:latest
    container_name: rag-nocodb
    ports:
      - "${NOCODB_PORT:-8090}:8080"
    volumes:
      - nocodb-data:/usr/app/data
    networks:
      - rag-net
    environment:
      NC_DB: "pg://postgres:5432?u=${POSTGRES_USER:-raguser}&p=${POSTGRES_PASSWORD:-changeme}&d=${NOCODB_DB:-nocodb}"
      NC_AUTH_JWT_SECRET: ${NOCODB_SECRET:-changeme}

  teable:
    restart: unless-stopped
    image: ghcr.io/teableio/teable:latest
    container_name: rag-teable
    ports:
      - "${TEABLE_PORT:-3002}:3000"
    networks:
      - rag-net
    depends_on:
      - postgres
    environment:
      PRISMA_DATABASE_URL: "postgresql://${POSTGRES_USER:-raguser}:${POSTGRES_PASSWORD:-changeme}@postgres:5432/${TEABLE_DB:-teable}"
      SECRET_KEY: ${TEABLE_SECRET:-changeme}
```

### 13.6 Переменные .env

```dotenv
# =====================
# POSTGRES
# =====================
POSTGRES_USER=raguser
POSTGRES_PASSWORD=changeme_strong_password
POSTGRES_DB=ragdb
POSTGRES_PORT=5432

# =====================
# REDIS / VALKEY
# =====================
REDIS_PORT=6379

# =====================
# QDRANT
# =====================
QDRANT_PORT=6333
QDRANT_API_KEY=

# =====================
# CHROMA
# =====================
CHROMA_PORT=8000
CHROMA_TOKEN=changeme

# =====================
# EMBEDDING / RERANKER
# =====================
EMBED_PORT=7997
RERANK_PORT=7998

# =====================
# MINIO
# =====================
MINIO_USER=minioadmin
MINIO_PASSWORD=changeme
MINIO_PORT=9000

# =====================
# MEM0
# =====================
MEM0_PORT=8080

# =====================
# RAGFLOW
# =====================
RAGFLOW_PORT=80

# =====================
# DOCLING
# =====================
DOCLING_PORT=5001

# =====================
# NEO4J (graph profile)
# =====================
NEO4J_USER=neo4j
NEO4J_PASS=changeme
NEO4J_HTTP=7474
NEO4J_BOLT=7687
LIGHTRAG_PORT=9621

# =====================
# UI PROFILE
# =====================
WEBUI_PORT=3000
ANYTHINGLLM_PORT=3001
OLLAMA_URL=http://host.docker.internal:11434

# =====================
# CMS PROFILE
# =====================
DIRECTUS_PORT=8055
DIRECTUS_SECRET=changeme_random_32chars
DIRECTUS_DB=directus
NOCODB_PORT=8090
NOCODB_SECRET=changeme
NOCODB_DB=nocodb
TEABLE_PORT=3002
TEABLE_SECRET=changeme
TEABLE_DB=teable

# =====================
# LLM
# =====================
LLM_BASE_URL=http://host.docker.internal:11434/v1
LLM_API_KEY=ollama
```

### 13.7 Схема инициализации PostgreSQL (configs/postgres/init.sql)

```sql
-- Создание extension pgvector
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- для BM25-like full-text

-- Базы данных для разных сервисов
CREATE DATABASE directus;
CREATE DATABASE nocodb;
CREATE DATABASE teable;
CREATE DATABASE mem0db;

-- Пример: таблица для хранения документов с эмбеддингами
CREATE TABLE IF NOT EXISTS document_chunks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doc_id      UUID NOT NULL,
    content     TEXT NOT NULL,
    embedding   VECTOR(1024),          -- BGE-M3 1024-dim
    metadata    JSONB,
    source      TEXT,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX ON document_chunks USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

CREATE INDEX ON document_chunks USING gin (to_tsvector('russian', content));
```

---

## 14. Выводы и рекомендации

### 14.1 Ключевые выводы

**Векторное хранилище:** Для self-hosted RAG оптимальна пара PostgreSQL+pgvector (до 50M векторов, SQL-запросы, транзакции) + Qdrant (высоконагруженный production с фильтрацией и sparse vectors). ChromaDB — только для dev.

**Эмбеддинг:** BGE-M3 — безусловный стандарт для production self-hosted. MIT-лицензия, 100+ языков, unified dense+sparse+ColBERT в одной модели, 8K context. Для максимального качества при наличии GPU — Qwen3-Embedding-8B (Apache 2.0, MTEB 70.58).

**Гибридный поиск:** BM25 + Dense Vector + Cross-Encoder Reranker — минимальный стек для качественного RAG. Одиночный vector search уступает на 15–25% по recall на реальных запросах.

**Парсинг:** Docling (MIT) — лучший выбор для коммерческих проектов. Для тяжёлых OCR-задач добавить Unstructured (Apache 2.0).

**GraphRAG:** LightRAG — лучший ROI. 65–80% экономии токенов vs Microsoft GraphRAG при сопоставимой точности. Activates при >1500 документов или при необходимости multi-hop reasoning.

**Память агентов:**
- Краткосрочная сессионная → **Redis/Valkey** (in-memory, TTL)
- Долговременная семантическая → **Mem0** (Apache 2.0, 3 строки кода, −90% токенов)
- Временна́я/graph → **Graphiti/Zep CE** (temporal KG, Apache 2.0)
- Полный agent runtime → **Letta** (Apache 2.0, OS-tiered, stateful)
- Наилучшая точность → **Hindsight** (MIT, 91.4% LongMemEval)

**RAG-платформа:** RAGFlow (Apache 2.0) — наилучшее document understanding; Dify (Apache 2.0) — наилучший workflow builder; AnythingLLM (MIT) — наилучший enterprise document workspace.

**Лицензирование для коммерции:** Все рекомендованные компоненты основного стека используют Apache 2.0 или MIT. Исключения: MinerU (AGPL), Marker (GPL), jina-v3 (CC BY-NC), Neo4j Community (GPL), Directus (BSL 1.1 — self-hosted бесплатно, SaaS-дистрибуция платная). **Для коммерческого встраивания** Neo4j заменяем на FalkorDB (SSPL/custom) или Apache AGE (Apache 2.0) при необходимости.

### 14.2 Рекомендуемый минимальный стек (Production-ready, коммерчески совместимый)

| Роль | Инструмент | Лицензия |
|---|---|---|
| Основная БД + мелкие векторы | PostgreSQL + pgvector | PostgreSQL License |
| Векторный store (production) | Qdrant | Apache 2.0 |
| Session memory | Valkey (Redis fork) | MIT |
| Long-term agent memory | Mem0 | Apache 2.0 |
| Embedding model | BGE-M3 | MIT |
| Embedding server | Infinity | MIT |
| Reranker | bge-reranker-v2-m3 | MIT |
| Document parser | Docling | MIT |
| RAG engine | RAGFlow или Dify | Apache 2.0 |
| Chat UI | Open WebUI | MIT |
| Workflow automation | n8n | Sustainable Use License |
| Object storage | MinIO | AGPL / SSPL (self-hosted free) |

### 14.3 Рекомендации по архитектуре для разных сценариев

| Сценарий | Рекомендация |
|---|---|
| Персональный ассистент | Архитектура A + Mem0 + AnythingLLM |
| Enterprise Knowledge Base | Архитектура B + Dify + Danswer/Onyx |
| Аналитика документов | Архитектура C (LightRAG + Neo4j) |
| Multi-agent система | Архитектура B + Letta + LangGraph |
| Прототип/разработка | Архитектура A (PostgreSQL+pgvector+ChromaDB) |
| Максимальная платформа | Архитектура D (полный стек) |

### 14.4 Расширение кастомными API и MCP

Стек готов к расширению через:
- **FastAPI / Flask** как custom API gateway над всеми сервисами
- **MCP Server** для интеграции в Claude, Cursor, n8n и другие MCP-клиенты
- **n8n custom nodes** — кастомные AI Tool nodes поверх RAG API
- Все сервисы основного стека экспонируют REST API для прямой интеграции

---

*Документ составлен на основе открытых источников, GitHub-репозиториев, бенчмарков и публикаций. Дата: март 2026.*
