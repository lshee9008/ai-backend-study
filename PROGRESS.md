# AI·백엔드 공부 진도

- 시작일: 2026-11-25
- 공부 시간: 하루 6시간 이상
- 원칙: 직접 만들고 돌려 보고 측정한 것만 "완료"로 적는다. 이력서에는 완성·측정 후에만 넣는다.

## 주제 순서
1. [ ] PostgreSQL + SQLAlchemy + Docker Compose로 FastAPI 서버 (ERD, 인덱스, 트랜잭션)
2. [ ] RAG: chunking → 임베딩 → pgvector → rerank → 출처 표시, BM25 비교
3. [ ] Tool calling 에이전트, LangGraph, MCP 서버
4. [ ] LLM 평가 자동화, Langfuse 트레이싱, AWS(EC2·RDS) 배포
5. [ ] 매일 코딩테스트 1~2문제 (프로그래머스 Lv.2)

## 주제 1: PostgreSQL + SQLAlchemy + Docker
| 단계 | 내용 | 상태 | 날짜 | 메모 |
|---|---|---|---|---|
| 1-1 | Docker Compose로 Postgres 띄우고 psql 접속 | 완료 | 2026-11-25 | 5433:5432로 접속 성공(server 16.16). 볼륨 유지 확인은 1-2 시작 때 `SELECT * FROM ping;`으로 |
| 1-2 | ERD 설계 + 테이블 생성 SQL | 진행 중 | 2026-11-25 | |
| 1-3 | JOIN·인덱스 실습 (EXPLAIN ANALYZE 전후 비교) | | | |
| 1-4 | 트랜잭션·격리 수준 실습 | | | |
| 1-5 | FastAPI + SQLAlchemy 2.0 연결, CRUD | | | |
| 1-6 | Alembic 마이그레이션 | | | |
| 1-7 | 앱까지 Dockerfile로 묶어 compose 하나로 실행 | | | |

## 코딩테스트 기록
| 날짜 | 문제 | 걸린 시간 | 메모 |
|---|---|---|---|

## 퀴즈·확인 질문 기록
- 2026-11-25 (1-1) `down` vs `down -v`: 맞음. `-v`는 볼륨까지 삭제해 DB가 초기화됨
- 2026-11-25 (1-1) 앱 컨테이너→DB 주소: 포트 5432는 맞음. 호스트는 `localhost`가 아니라 서비스 이름 `db` → `postgresql://study:study@db:5432/study`

## 배운 점·트러블슈팅
- 2026-11-25 포트 매핑은 `"호스트:컨테이너"`. 뒤 숫자는 컨테이너 안 프로그램(Postgres=5432)이 정하고, 바꿀 수 있는 건 앞 숫자뿐
- 2026-11-25 에러로 구분하기
  - `server closed the connection unexpectedly`: 호스트 포트는 열렸지만 컨테이너 안에서 그 포트를 아무도 안 받음 (5433:5433)
  - `Connection refused`: 호스트의 그 포트를 아무도 안 열었음 (매핑에 5433 없음)
  - `role "study" does not exist`: 서버엔 붙었지만 엉뚱한 서버(-p 빠져서 로컬 Postgres 5432)
- 2026-11-25 경고 없이 접속: `docker compose exec db psql -U study -d study`

## 진행 방식 메모
- 빈칸 채우기 대신, 주석으로 자세히 설명한 코드를 보고 직접 입력·실행하는 방식 (2026-11-25부터)
