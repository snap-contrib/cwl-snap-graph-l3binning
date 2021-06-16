$graph:
- baseCommand: gpt
  hints:
    DockerRequirement:
      dockerPull: snap:latest
  class: CommandLineTool
  id: clt
  inputs:
    inp1:
      inputBinding:
        position: 1
      type: File

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


  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /srv/conda/envs/env_snap/snap/bin:/usr/share/java/maven/bin:/usr/share/java/maven/bin:/opt/anaconda/bin:/opt/anaconda/condabin:/opt/anaconda/bin:/usr/lib64/qt-3.3/bin:/usr/share/java/maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
        PREFIX: /opt/anaconda/envs/env_snap
    ResourceRequirement: {}
    InlineJavascriptRequirement: {}
  stderr: std.err
  stdout: std.out

- class: Workflow
  doc: SNAP SAR Calibration
  id: main
  inputs:
    snap_graph:
      doc: SNAP Graph
      label: SNAP Graph
      type: File
    s3-inputs:
      doc: Sentinel-3 SAFE Directory
      label: Sentinel-3 SAFE Directory
      type: Directory[]
  label: SNAP Level-3 binning
  outputs:
  - id: wf_outputs
    outputSource:
    - node_1/results
    type: Directory
  
  requirements:
  - class: SubworkflowFeatureRequirement
  
  steps:
    node_1:
      in:
        inp1: snap_graph
        inp2: s3-inputs
      out:
      - results
      run: '#clt'
cwlVersion: v1.0
