# Dockerfile at repository root
FROM ubuntu:22.04

# 1. base tooling
RUN apt-get update && \
    apt-get install -y git curl build-essential npm && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    npm install -g snarkjs

# 2. circom compiler (built once, cached)
RUN git clone --depth 1 https://github.com/iden3/circom.git && \
    cd circom && cargo build --release && \
    cp target/release/circom /usr/local/bin

# 3. project sources
WORKDIR /usr/src/app
COPY . .

# 4. node deps (merkle helpers + tests)
RUN npm ci

CMD ["bash"]   # drop into a shell for interactively running make/test
