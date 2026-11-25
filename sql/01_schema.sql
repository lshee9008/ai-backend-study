-- ============================================================
-- 01_schema.sql : 문서 기반 Q&A 서비스의 기본 테이블
-- 실행: docker compose exec -T db psql -U study -d study < sql/01_schema.sql
-- ============================================================

-- 파일을 여러 번 실행해도 되도록, 기존 테이블을 먼저 지운다.
-- 다른 테이블이 참조하는 테이블은 그냥 지울 수 없으므로 CASCADE로 참조까지 함께 정리한다.
-- (연습용이라 괜찮은 방식이다. 운영 DB에서는 절대 이렇게 하지 않고, 1-6에서 배울 Alembic 마이그레이션을 쓴다.)
DROP TABLE IF EXISTS question_sources, questions, chunks, documents, users CASCADE;

-- ------------------------------------------------------------
-- users : 사용자
-- ------------------------------------------------------------
CREATE TABLE users (
    -- PK. GENERATED ALWAYS AS IDENTITY = DB가 1, 2, 3... 번호를 자동으로 매긴다.
    -- (예전 방식인 SERIAL보다 표준에 가까운 최신 방식)
    -- bigint: int(약 21억)보다 범위가 넓은 정수. id는 보통 bigint로 둔다.
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- NOT NULL: 비워 둘 수 없다. UNIQUE: 같은 이메일로 두 번 가입할 수 없다.
    -- UNIQUE를 걸면 Postgres가 내부적으로 인덱스를 자동으로 만든다 (1-3에서 확인).
    email       text NOT NULL UNIQUE,
    name        text NOT NULL,

    -- timestamptz: 시간대 정보까지 저장하는 시각 타입. 서버 시간대가 달라도 헷갈리지 않는다.
    -- DEFAULT now(): 값을 안 넣으면 INSERT하는 순간의 시각이 들어간다.
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- documents : 업로드한 문서 (users 1 : N documents)
-- ------------------------------------------------------------
CREATE TABLE documents (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- FK: users.id에 실제로 있는 값만 들어갈 수 있다.
    -- ON DELETE CASCADE: 사용자를 지우면 그 사용자의 문서도 자동으로 지워진다.
    --   다른 선택지: RESTRICT(문서가 남아 있으면 사용자 삭제를 막음), SET NULL(FK를 비움)
    user_id     bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    title       text NOT NULL,
    source_url  text,              -- NOT NULL이 없으니 비워도 된다 (직접 쓴 메모 등은 URL이 없음)
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- chunks : 문서를 나눈 조각 (documents 1 : N chunks)
-- 2주차 RAG에서 여기에 embedding vector 컬럼을 추가한다.
-- ------------------------------------------------------------
CREATE TABLE chunks (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    document_id  bigint NOT NULL REFERENCES documents(id) ON DELETE CASCADE,

    -- 문서 안에서 몇 번째 조각인지 (0, 1, 2 ...). 출처를 보여 줄 때 순서를 복원하는 데 쓴다.
    chunk_index  int  NOT NULL,
    content      text NOT NULL,

    -- CHECK: 값이 조건을 만족해야만 저장된다. 토큰 수가 0 이하인 조각은 말이 안 되므로 막는다.
    token_count  int  CHECK (token_count > 0),

    -- 복합 UNIQUE: 같은 문서 안에서 같은 순번의 조각이 두 번 들어가는 것을 막는다.
    -- (문서 A의 0번과 문서 B의 0번은 서로 달라서 괜찮다)
    UNIQUE (document_id, chunk_index)
);

-- ------------------------------------------------------------
-- questions : 질문과 답변 기록 (users 1 : N questions)
-- 4주차 평가·트레이싱에서 model, latency_ms를 분석에 쓴다.
-- ------------------------------------------------------------
CREATE TABLE questions (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question    text NOT NULL,
    answer      text,                          -- 답변 생성 전이거나 실패하면 비어 있을 수 있다
    model       text,                          -- 어떤 모델로 답했는지 (폴백을 썼다면 실제 사용된 모델)
    latency_ms  int CHECK (latency_ms >= 0),   -- 응답에 걸린 시간(ms). 음수는 막는다
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- question_sources : 질문 ↔ 청크 연결 테이블 (N : M)
-- "이 답변은 어떤 청크를 근거로 했는가" = 출처 표시
-- ------------------------------------------------------------
CREATE TABLE question_sources (
    question_id  bigint NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    chunk_id     bigint NOT NULL REFERENCES chunks(id)    ON DELETE CASCADE,

    -- 검색 결과에서 몇 위였는지 (1위, 2위 ...). rerank 전후 비교에도 쓴다.
    rank         int NOT NULL CHECK (rank >= 1),

    -- 복합 PK: (질문, 청크) 쌍 자체가 행을 구분한다.
    -- 같은 질문에 같은 청크가 두 번 연결되는 것을 막아 준다. 연결 테이블에는 따로 id를 두지 않았다.
    PRIMARY KEY (question_id, chunk_id)
);