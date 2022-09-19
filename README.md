# MicrobialIdentificationNextflowPipeline

An automated genome analysis workflow to identify bacterial isolates from infected wildlife samples using the Nextflow platform.

#  Tools required

<details>
  <summary>
  Nextflow installed on the cluster being used
  </summary>
  <br>
  a. Nextflow requires Bash 3.2 or later and Java 11 till 18 to be installed on the cluster
  </br>
  </br>
  b. Depending on the cluster program management loader, module loading can vary. An example of checking for module nextflow on SLURM (Simple Linux Utility for Resource Management) is the following:
  
  ```bash scripting
    $ module spider nextflow
  ```
  c. The output then looks like such:
  
  ```bash scripting
    -------------------------------------------------------------------------
    nextflow: nextflow/21.10.6
    -------------------------------------------------------------------------

    This module can be loaded directly: module load nextflow/21.10.6

    Help:
      Nextflow: Data-driven computational pipelines
      Nextflow enables scalable and reproducible scientific workflows using software containers. It allows the 
      adaptation of pipelines written in the most common scripting languages.
      Its fluent DSL simplifies the implementation and the deployment of complex parallel and 
      reactive workflows on clouds and clusters.
  ```

</details>

<details>
  <summary>
  Workflow specific programs
  </summary>
  <br>
  These need to also be installed on the cluster:
    </br>
    a. FastQC
    </br>
    b. Timmomatic
    </br>
    c. Unicycler
    </br>
    d. QUAST
    </br>
    e. BLAST
    </br>
    f. FastANI
    </br>
    g. Barrnap
    
</details>

# Steps to run

<details>
  <summary>
    Clone this repository
  </summary>
  <br>
  a. Make sure git is installed by typing the following in the command prompt:
  
  ```bash scripting
    $ git --version
  ```
  
  b. Then clone this repository:
  
  ```bash scripting
    $ git clone https://github.com/WyoARCC-Research/MicrobialIdentificationNextflowPipeline.git
  ```
</details>

<details>
  <summary>
    Load the nextflow module
  </summary>
  <br>
  Depending on the cluster program management loader, module loading can vary. An example of loading the nextflow module on SLURM (Simple Linux Utility for Resource Management) is the following:
  
  ```bash scripting
    $ module load nextflow
  ```
</details>

<details>
  <summary>
    Within the nextflow.config
  </summary>
  <br>
  a. Open the nextflow.config file, cloned from the repository, in a text editor.
  </br>
  </br>
  b.


  
