# SNAP L3-Binning using docker and the Common Workflow Language (CWL)

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
git clone https://github.com/snap-contrib/cwl-snap-l3binning.git
cd cwl-snap-l3binning
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

### Getting a few Sentinel-3 OLCI Level-2 acquistions

Download a set of Sentinel-3 OLCI Level-2 acquisitions and unzip them.

### Preparing the input parameters for the CWL step

The CWL parameters file is a YAML file with an array of input directories pointing to the SAFE folders:

```yaml
s3-inputs:
- {'class': 'Directory', 'path': '/home/fbrito/Downloads/s3-binning-data/S3A_OL_2_LFR____20210531T103155_20210531T103455_20210601T160331_0179_072_222_2160_LN1_O_NT_002.SEN3' }
- {'class': 'Directory', 'path': '/home/fbrito/Downloads/s3-binning-data/S3A_OL_2_LFR____20210531T103455_20210531T103755_20210601T160350_0180_072_222_2340_LN1_O_NT_002.SEN3'}
- {'class': 'Directory', 'path': '/home/fbrito/Downloads/s3-binning-data/S3B_OL_2_LFR____20210514T103335_20210514T103635_20210515T153746_0179_052_222_2160_LN1_O_NT_002.SEN3'}
- {'class': 'Directory', 'path': '/home/fbrito/Downloads/s3-binning-data/S3B_OL_2_LFR____20210514T103635_20210514T103935_20210515T153759_0179_052_222_2340_LN1_O_NT_002.SEN3' }
- {'class': 'Directory', 'path': '/home/fbrito/Downloads/s3-binning-data/S3B_OL_2_LFR____20210610T103340_20210610T103640_20210611T153941_0179_053_222_2160_LN1_O_NT_002.SEN3' }
- {'class': 'Directory', 'path': '/home/fbrito/Downloads/s3-binning-data/S3B_OL_2_LFR____20210610T103640_20210610T103940_20210611T154001_0179_053_222_2340_LN1_O_NT_002.SEN3' }
snap_graph: {class: File, path: ./l3-binning.xml}
```

Save this content in a file called `s3-params.yml`.

### The SNAP Graph

The file `l3-binning.xml` contains a SNAP Graph that is parametrized with variables:

```xml
<graph id="Graph">
<version>1.0</version>
  <node id="Read">
    <operator>Binning</operator>
<parameters>
    <sourceProductPaths>$inFiles</sourceProductPaths>
    <sourceProductFormat>Sen3</sourceProductFormat>
    <timeFilterMethod>NONE</timeFilterMethod>
    ...
```

The CWL file will instruct `gpt` to use the value passed as a command line argument:

```yaml
    inp2:
      type: Directory[]
      inputBinding:
        prefix: -PinFiles=
        valueFrom: |
          ${
              function myFunction(value, index, array) {
                  return value.path + "/*.xml";
              }
              return inputs.inp2.map(myFunction).join();
          }
        position: 2
        separate: false
```

The Javascript short code will add `/*.xml` to each Sentinel-3 folder as this is what SNAP `gpt` expects to find in the `sourceProductPaths` SNAP Graph element.

### Run the SNAP graph with CWL in the container

```console
cwltool gpt-l3-binning.cwl s3-params.yml
```

This will process the Sentinel-1 GRD acquisitions with an output as:

```console
INFO /srv/conda/bin/cwltool 3.0.20210319143721
INFO Resolved 'gpt-l3-binning.cwl' to 'file:///home/fbrito/work/cwl-snap-graph-l3binning/gpt-l3-binning.cwl'
INFO [workflow ] start
INFO [workflow ] starting step node_1
INFO [step node_1] start
INFO [job node_1] /tmp/tizozsjv$ docker \
    run \
    -i \
    --mount=type=bind,source=/tmp/tizozsjv,target=/SOSFSH \
    --mount=type=bind,source=/tmp/jk258rnl,target=/tmp \
    --mount=type=bind,source=/home/fbrito/work/cwl-snap-graph-l3binning/l3-binning.xml,target=/var/lib/cwl/stg1f56340e-7b79-4155-b572-a1165ebe8f89/l3-binning.xml,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/s3-binning-data/S3A_OL_2_LFR____20210531T103155_20210531T103455_20210601T160331_0179_072_222_2160_LN1_O_NT_002.SEN3,target=/var/lib/cwl/stg7e6a584b-cfb7-4297-9578-9e69b16a736d/S3A_OL_2_LFR____20210531T103155_20210531T103455_20210601T160331_0179_072_222_2160_LN1_O_NT_002.SEN3,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/s3-binning-data/S3A_OL_2_LFR____20210531T103455_20210531T103755_20210601T160350_0180_072_222_2340_LN1_O_NT_002.SEN3,target=/var/lib/cwl/stg223ec947-2167-4a3e-81f7-12e101e8bc84/S3A_OL_2_LFR____20210531T103455_20210531T103755_20210601T160350_0180_072_222_2340_LN1_O_NT_002.SEN3,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/s3-binning-data/S3B_OL_2_LFR____20210514T103335_20210514T103635_20210515T153746_0179_052_222_2160_LN1_O_NT_002.SEN3,target=/var/lib/cwl/stgb500d30b-9094-4f63-a0e6-a4d4e65a63ed/S3B_OL_2_LFR____20210514T103335_20210514T103635_20210515T153746_0179_052_222_2160_LN1_O_NT_002.SEN3,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/s3-binning-data/S3B_OL_2_LFR____20210514T103635_20210514T103935_20210515T153759_0179_052_222_2340_LN1_O_NT_002.SEN3,target=/var/lib/cwl/stgf1da9966-28c5-4ff2-bc89-c20bb344c78e/S3B_OL_2_LFR____20210514T103635_20210514T103935_20210515T153759_0179_052_222_2340_LN1_O_NT_002.SEN3,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/s3-binning-data/S3B_OL_2_LFR____20210610T103340_20210610T103640_20210611T153941_0179_053_222_2160_LN1_O_NT_002.SEN3,target=/var/lib/cwl/stg79046bae-49d5-4b81-a963-8032fba09127/S3B_OL_2_LFR____20210610T103340_20210610T103640_20210611T153941_0179_053_222_2160_LN1_O_NT_002.SEN3,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/s3-binning-data/S3B_OL_2_LFR____20210610T103640_20210610T103940_20210611T154001_0179_053_222_2340_LN1_O_NT_002.SEN3,target=/var/lib/cwl/stg532d9c2b-ec54-4553-96e7-3e0028d0dc3a/S3B_OL_2_LFR____20210610T103640_20210610T103940_20210611T154001_0179_053_222_2340_LN1_O_NT_002.SEN3,readonly \
    --workdir=/SOSFSH \
    --read-only=true \
    --log-driver=none \
    --user=1000:1000 \
    --rm \
    --env=TMPDIR=/tmp \
    --env=HOME=/SOSFSH \
    --cidfile=/tmp/3nq038sj/20210616150736-020082.cid \
    --env=PATH=/srv/conda/envs/env_snap/snap/bin:/usr/share/java/maven/bin:/usr/share/java/maven/bin:/opt/anaconda/bin:/opt/anaconda/condabin:/opt/anaconda/bin:/usr/lib64/qt-3.3/bin:/usr/share/java/maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin \
    --env=PREFIX=/opt/anaconda/envs/env_snap \
    snap:latest \
    gpt \
    /var/lib/cwl/stg1f56340e-7b79-4155-b572-a1165ebe8f89/l3-binning.xml \
    -PinFiles=/var/lib/cwl/stg7e6a584b-cfb7-4297-9578-9e69b16a736d/S3A_OL_2_LFR____20210531T103155_20210531T103455_20210601T160331_0179_072_222_2160_LN1_O_NT_002.SEN3/*.xml,/var/lib/cwl/stg223ec947-2167-4a3e-81f7-12e101e8bc84/S3A_OL_2_LFR____20210531T103455_20210531T103755_20210601T160350_0180_072_222_2340_LN1_O_NT_002.SEN3/*.xml,/var/lib/cwl/stgb500d30b-9094-4f63-a0e6-a4d4e65a63ed/S3B_OL_2_LFR____20210514T103335_20210514T103635_20210515T153746_0179_052_222_2160_LN1_O_NT_002.SEN3/*.xml,/var/lib/cwl/stgf1da9966-28c5-4ff2-bc89-c20bb344c78e/S3B_OL_2_LFR____20210514T103635_20210514T103935_20210515T153759_0179_052_222_2340_LN1_O_NT_002.SEN3/*.xml,/var/lib/cwl/stg79046bae-49d5-4b81-a963-8032fba09127/S3B_OL_2_LFR____20210610T103340_20210610T103640_20210611T153941_0179_053_222_2160_LN1_O_NT_002.SEN3/*.xml,/var/lib/cwl/stg532d9c2b-ec54-4553-96e7-3e0028d0dc3a/S3B_OL_2_LFR____20210610T103640_20210610T103940_20210611T154001_0179_053_222_2340_LN1_O_NT_002.SEN3/*.xml > /tmp/tizozsjv/std.out 2> /tmp/tizozsjv/std.err
INFO [job node_1] Max memory used: 9911MiB
INFO [job node_1] completed success
INFO [step node_1] completed success
INFO [workflow ] completed successs
```


