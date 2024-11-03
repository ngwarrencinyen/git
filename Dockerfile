# clickhouse-xdr-internal-hyperscan

ARG OS_VER=22.04
ARG OS_IMAGE=ubuntu

FROM ${OS_IMAGE}:${OS_VER} as build

RUN apt-get update && apt-get install -y \
    git cmake wget curl ccache nasm yasm ninja-build lsb-release wget software-properties-common gnupg

WORKDIR /root

# Clang
ARG CLANG_VER=17
ARG CLANG_REPO=https://apt.llvm.org
RUN wget ${CLANG_REPO}/llvm.sh \
    && sed -i 's/add-apt-repository "${REPO_NAME}"/add-apt-repository -y "${REPO_NAME}"/g' llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh ${CLANG_VER}
ENV CC=clang-${CLANG_VER}
ENV CXX=clang++-${CLANG_VER}

# Clickhouse
ARG CLICKHOUSE_VER=v24.4.1.2088-stable
ARG CLICKHOUSE_REPO=https://github.com/ClickHouse/ClickHouse.git
ARG CLICKHOUSE_PATCH=clickhouse_internal_hyperscan_5_6_1.patch
COPY ./patch/${CLICKHOUSE_PATCH} /
RUN git clone ${CLICKHOUSE_REPO} \
    && cd ClickHouse \
    && git checkout -b ${CLICKHOUSE_VER} ${CLICKHOUSE_VER} \
    && git apply /${CLICKHOUSE_PATCH} \
    && git add . \
    && git submodule update --init

# Internal HyperScan
ARG HYPERSCAN_VER=v5.6.1
ARG HYPERSCAN_REPO=https://github.com/intel-innersource/networking.dataplane.hyperscan.ue2.git
RUN --mount=type=secret,id=my_netrc,dst=/root/.netrc \
    cd ClickHouse/contrib \
    && git clone ${HYPERSCAN_REPO} hyperscan \
    && cd hyperscan \
    && git checkout -b ${HYPERSCAN_VER} ${HYPERSCAN_VER} \
    && git apply ../hyperscan-cmake/patch/hyperscan.patch \
    && git add . 

# Build ClickHouse with HyperScan
RUN cd ClickHouse \
    && mkdir build \
    && cmake -S . -B build \
    && cmake --build build --target clickhouse

# Dataset
ARG DATASET_VER=v1
ARG DATASET_REPO=https://datasets.clickhouse.com/hits/tsv/hits_${DATASET_VER}.tsv.xz
RUN cd /root \
    && curl ${DATASET_REPO} | unxz --threads=`nproc` > hits_${DATASET_VER}.tsv \
    && tar -zcvf hits_${DATASET_VER}.tsv.tgz hits_${DATASET_VER}.tsv


FROM ${OS_IMAGE}:${OS_VER}

WORKDIR /root

RUN apt-get update && apt-get install -y vim gawk

ARG CLICKHOUSE_DIR=/root/clickhouse/
COPY --from=build /root/ClickHouse/build/programs/clickhouse ${CLICKHOUSE_DIR}
COPY --from=build /root/hits_v1.tsv.tgz ${CLICKHOUSE_DIR}
COPY scripts/*.sh ${CLICKHOUSE_DIR}
COPY config/clickhouse/*.xml ${CLICKHOUSE_DIR}
COPY kpi.sh ${CLICKHOUSE_DIR}

ENV CLIENT_CORE_LIST=0-0
ENV SERVER_CORE_LIST=1-1
ENV SERVER_MAX_THREADS=1

RUN chmod +x ${CLICKHOUSE_DIR}/*.sh
RUN mkfifo /export-logs
CMD ./clickhouse/run_test.sh && \
    ./clickhouse/kpi.sh && \
    sleep 5


