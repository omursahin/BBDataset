# ============================================================================
# MODIFIED: vampi Dockerfile moved to dockerfiles directory
# No significant changes needed - already uses multi-stage build
# ============================================================================

FROM python:3.11-alpine as builder
RUN apk --update add bash nano g++
COPY ./requirements.txt /vampi/requirements.txt
WORKDIR /vampi
RUN pip install -r requirements.txt

# Build a fresh container, copying across files & compiled parts
FROM python:3.11-alpine
COPY . /vampi
WORKDIR /vampi
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin

# Fix Windows CRLF line endings for Python files
RUN find /vampi -name "*.py" -type f -exec sed -i 's/\r$//' {} \;

ENV vulnerable=1
ENV tokentimetolive=60

ENTRYPOINT ["python"]
CMD ["app.py"]
