# Process SNAP GPT graphs using docker and the Common Workflow Language (CWL)

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

This repo provides a method to process Earth Observation data with the SNAP Graph Processing Tool (GPT) using docker and CWL.

With this method, the host machine does not have to have SNAP installed. 

CWL is used to invoke the SNAP `gpt` command line tool and deals with all the docker volume mounts required to process a Graph and EO data available on the host.

This repo contains a SNAP Graph for the SAR calibration of Copernicus Sentinel-1 GRD product. You're expected to have the product on your local computer


## Requirements

### CWL runner

The CWL runner executes CWL documents. 

Follow the installation procedure provided [here](https://github.com/common-workflow-language/cwltool#install)

### Docker

The SNAP processing runs in a docker container so docker is required. 

Follow the installation steps for your computer provided [here](https://docs.docker.com/get-docker/)

If needed follow the additional steps described [here](https://docs.docker.com/engine/install/linux-postinstall/) to allow the CWL runner to manage docker as a non-root user.

## Getting started 

### Setting-up the container

Clone this repository and build the docker image with:

```console
git clone https://github.com/snap-contrib/cwl-snap-graph-runner.git
cd cwl-snap-graph-runner
docker build -t snap:latest -f .docker/Dockerfile .
```

Check the docker image exists with:

```console
docker images | grep snap:latest
```

This returns one line with the docker image just built.

Check if SNAP `gpt` utility is available in the container:

```console
docker run --rm -it snap:latest gpt -h
```

This dumps the SNAP `gpt` utiliy help message.

### Getting a few Sentinel-1 GRD acquistions

Download a couple of Sentinel-1 GRD acquisitions and unzip them.

### Preparing the input parameters for the CWL step

The CWL parameters file is a YAML file with an array of input directories pointing to the SAFE folders:

```yaml
polarization: 'VV'
snap_graph: {class: File, path: ./sar-calibration.xml}
safe: 
- {'class': 'Directory', 'path': '/home/fbrito/Downloads/S1A_IW_GRDH_1SDV_20210615T050457_20210615T050522_038346_048680_F42E.SAFE'}
```

Save this content in a file called `params.yml`.

### The SNAP Graph

The file `sar-calibration.xml` contains a SNAP Graph that is parametrized with variables:

```xml
<node id="Read">
    <operator>Read</operator>
    <sources/>
    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
      <file>${inFile}</file>
      <formatName>SENTINEL-1</formatName>
    </parameters>
  </node>
```

The CWL file will instruct `gpt` to use the value passed as a command line argument:

```yaml
inp3:
  inputBinding:
    position: 2
    prefix: -PinFile=
    separate: false
  type: Directory
```

### Run the SNAP graph with CWL in the container

```console
cwltool gpt-sar-calibration.cwl gpt-sar-calibration-params.yml
```

This will process the Sentinel-1 GRD acquisitions with an output as:

```console
INFO /srv/conda/bin/cwltool 3.0.20210319143721
INFO Resolved 'gpt-sar-calibration.cwl' to 'file:///home/fbrito/work/cwl-snap-graph-runner/gpt-sar-calibration.cwl'
INFO [workflow ] start
INFO [workflow ] starting step node_1
INFO [step node_1] start
INFO [job node_1] /tmp/9ti8kfl0$ docker \
    run \
    -i \
    --mount=type=bind,source=/tmp/9ti8kfl0,target=/zefIeZ \
    --mount=type=bind,source=/tmp/f2jfo_i7,target=/tmp \
    --mount=type=bind,source=/home/fbrito/work/cwl-snap-graph-runner/sar-calibration.xml,target=/var/lib/cwl/stg52f9db5f-3988-4923-97d6-8f02f538b99c/sar-calibration.xml,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/S1A_IW_GRDH_1SDV_20210615T050457_20210615T050522_038346_048680_F42E.SAFE,target=/var/lib/cwl/stg83984c21-caf6-4b14-b2b0-893583bcd1b9/S1A_IW_GRDH_1SDV_20210615T050457_20210615T050522_038346_048680_F42E.SAFE,readonly \
    --workdir=/zefIeZ \
    --read-only=true \
    --log-driver=none \
    --user=1000:1000 \
    --rm \
    --env=TMPDIR=/tmp \
    --env=HOME=/zefIeZ \
    --cidfile=/tmp/sub7uryv/20210616102403-516906.cid \
    --env=PATH=/srv/conda/envs/env_snap/snap/bin:/usr/share/java/maven/bin:/usr/share/java/maven/bin:/opt/anaconda/bin:/opt/anaconda/condabin:/opt/anaconda/bin:/usr/lib64/qt-3.3/bin:/usr/share/java/maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin \
    --env=PREFIX=/opt/anaconda/envs/env_snap \
    snap:latest \
    gpt \
    /var/lib/cwl/stg52f9db5f-3988-4923-97d6-8f02f538b99c/sar-calibration.xml \
    -PselPol=VV \
    -PinFile=/var/lib/cwl/stg83984c21-caf6-4b14-b2b0-893583bcd1b9/S1A_IW_GRDH_1SDV_20210615T050457_20210615T050522_038346_048680_F42E.SAFE > /tmp/9ti8kfl0/std.out 2> /tmp/9ti8kfl0/std.err
INFO [job node_1] Max memory used: 7174MiB
INFO [job node_1] completed success
INFO [step node_1] completed success
INFO [workflow ] completed success
```

## Run your own SNAP graphs

Use the approach provided to run your own SNAP graphs

1. Create your own repo with this one as a template using the URL https://github.com/snap-contrib/cwl-snap-graph-runner/generate

2. Create the SNAP graphs including the variable to be used in the CWL as parameters

3. Write the CWL document to expose the SNAP Graph parameters you want to provide at execution time

4. Write the YAML parameters file 

5. Run the CWL document
