## Introduction

ClickHouse® is an open-source column-oriented DBMS (Columnar Database Management System) for online analytical processing (OLAP) that allows users to generate analytical reports using SQL queries in real-time.
This benchmark can be used to evaluate the performance of ClickHouse in XDR (Extended Detection and Response) scenarios, and by using native HyperScan, it can accelerate the query performance of ClickHouse on multi-regular expression matching operations.

This guide will walk you through building and running a Docker image for ClickHouse with HyperScan integration. You will also learn how to set parameters for [`CLIENT_CORE_LIST`], [`SERVER_CORE_LIST`], and [`SERVER_MAX_THREADS`], and how to retrieve query execution times.

## Prerequisites
- Docker installed on your machine.
- Internet connection to download necessary files and dependencies.
- Configure CPU Freq & Uncore Freq using [CommsPowerManagement](https://github.com/intel/CommsPowerManagement) for maximum performance.
> ***Note**: Make sure to adjust to maximum CPU Freq & Uncore Freq and Perf Policy = performance.*

## Step 1: Prepare the `.netrc` File

Create a `.netrc` file with your GitHub credentials. This file will be used to authenticate with GitHub during the Docker build process.
> ***Note**: Create the `.netrc` file within the same directory with the Dockerfile*

```plaintext
machine github.com
    login not-used
    password <your_personal_access_token>
machine api.github.com
    login not-used
    password <your_personal_access_token>
```

Replace  `your_personal_access_token` with your GitHub personal access token.

## Step 2: Join Docker Swarm

Initialize Docker Swarm mode on your machine to enable the creation of Docker secrets.

```bash
docker swarm init
```

## Step 3: Create the Docker Secret

Use the Docker CLI to create a secret from the `.netrc` file.

```bash
docker secret create my_netrc .netrc
```

## Step 4: (Optional) Configure Proxy Settings

If you are behind a firewall and proxy, you need to configure proxy settings for Docker. Create or edit the Docker client configuration file to include the proxy settings.


```sh
nano ~/.docker/config.json
```


Add the following JSON configuration to the file:

```json
{
  "proxies": {
    "default": {
      "httpProxy": "http://your-proxy-server:port",
      "httpsProxy": "http://your-proxy-server:port",
      "noProxy": "localhost,127.0.0.1"
    }
  }
}
```

Replace `http://your-proxy-server:port` with the actual address and port of your proxy server.

## Step 5: Build the Docker Image with BuildKit

Enable Docker BuildKit and build the Docker image, passing the secret:

```bash
DOCKER_BUILDKIT=1 docker build --secret id=my_netrc,src=.netrc -t clickhouse-hyperscan .
```

## Step 6: Run the Docker Container

You can run the Docker container with default parameters or specify custom parameters.

### Run with Default Parameters

```bash
docker run clickhouse-hyperscan
```

### Run with Custom Parameters

You can override the default parameters by specifying environment variables:

```bash
docker run -e CLIENT_CORE_LIST=2-2 -e SERVER_CORE_LIST=3-3 -e SERVER_MAX_THREADS=2 clickhouse-hyperscan
```

### Parameters

- **[`CLIENT_CORE_LIST`]**: Specifies the core list for the client. Default is `0-0`.
- **[`SERVER_CORE_LIST`]**: Specifies the core list for the server. Default is `1-1`.
- **[`SERVER_MAX_THREADS`]**: Specifies the maximum number of threads for the server. Default is [`1`].

## Step 7: Retrieve Query Execution Times

After running the container, the `run_test.sh` script will execute, followed by the `kpi.sh` script to process the log files.

Below 5 queries (query1 to query5) are used to measure HyperScan regular expression performance:
- `Query 'query1' execution time(s)`: The execution time(s) of query1.
- `Query 'query2' execution time(s)`: The execution time(s) of query2.
- `Query 'query3' execution time(s)`: The execution time(s) of query3.
- `Query 'query4' execution time(s)`: The execution time(s) of query4.
- `Query 'query5' execution time(s)`: The execution time(s) of query5.
- `Average execution time(s) of query1 to query5`: The average execution time(s) of the above 5 queries.

Below 2 queries (query6 and query7) are used to show HyperScan benefits by comparing SQL fuzzy query performance and HyperScan query performance:
- `Query 'query6' execution time(s)`: The execution time(s) of query6 for SQL fuzzy query.
- `Query 'query7' execution time(s)`: The execution time(s) of query7 for HyperScan query.

The processed output will be printed to the console.

### Example Output
Output values are in seconds(s).
```sh 
Query 'query1' execution time(s): 1.56
Query 'query2' execution time(s): 1.34
Query 'query3' execution time(s): 1.78
Query 'query4' execution time(s): 1.45
Query 'query5' execution time(s): 1.67
Query 'query6' execution time(s): 3.67
Query 'query7' execution time(s): 1.68
*Average execution time of query1 to query5(s): 1.560
```

## Contact
If you encounter any issues, please contact:
- Stage 1 Contact: [Ng Warren](mailto:warren.cin.yen.ng@intel.com)
- Testing for git push