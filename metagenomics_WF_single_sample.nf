nextflow.enable.dsl = 2

/** ************************************************************************************************ */
process uncompress {
	input:
		val comFiles
	output:
		stdout
	"""
	gunzip "${comFiles}"
	wait
	"echo -n ${comFiles}" | sed 's/\\.gz\$//'
	"""		
}

process fastqcRun {
	input:
		val file
	output:
		stdout
	"""
	module load miniconda3
	conda activate /pfs/tc1/project/arcc-students/bio2
	fastqc -o "${params.output}"  "${file}"
	"""
}


process TrimSequences_PE {
	label 'Trimmomatic_PE'
	publishDir "${params.output}/trimmomatic_results"       
        input:
                val Threads                  // Number of threads
		path InputRead1              // Input Read File
                path InputRead2              // Input Read File 
		val SampleName               // Name of the Sample (PE)
		val headcrop		     // Value of HEADCROP
		val trailing		     // Value of TRAILING
		val minlenPE		     // Value of MINLEN (PE)

        output:
               path "${SampleName}.1P.fastq"
	       path "${SampleName}.2P.fastq"

        script:
                """

                module load nextflow
                module load swset/2018.05
                module load gcc/7.3.0
                module load trimmomatic/0.36
		module load miniconda3
		conda activate /pfs/tc1/project/arcc-students/bio2

                trimmomatic PE -threads ${Threads} ${InputRead1} ${InputRead2} ${SampleName}.1P.fastq ${SampleName}.1UP.fastq ${SampleName}.2P.fastq ${SampleName}.2UP.fastq HEADCROP:${headcrop} TRAILING:${trailing} MINLEN:${minlenPE}

                """
}

process TrimSequences_SE {
	label 'Trimmomatic_SE'
	publishDir "${params.output}/trimmomatic_results"
        input:
                val Threads                  // Number of threads
                path LongRead                // Long Read File
                val SampleName               // Name of the Sample (SE)
		val minlenSE

        output:
               path "${SampleName}longtrim.fastq"

        script:
            	"""

                trimmomatic SE -threads ${Threads} -phred33 ${LongRead} ${SampleName}longtrim.fastq MINLEN:${minlenSE}

                """
}

process Unicycler_Hybrid_Assembly {
	label 'unicycler'
        publishDir "${params.output}/unicycler_results"
        input: 
		path Input_Short_Read_1
		path Input_Short_Read_2
		path Input_Long_Read
                val Threads
                path Output

        output:
		path("output/assembly.fasta"), emit: contigs
        script:
                """

		module load miniconda3
		conda activate /pfs/tc1/project/arcc-students/bio2
                
		unicycler -1 ${Input_Short_Read_1} -2 ${Input_Short_Read_2} -l ${Input_Long_Read} -t ${Threads} -o ${Output}
                
		"""
}

process quastRun {
	label 'quast'
	publishDir "${params.output}/quast_results"
	input:
		path contigs
		path output
		val Threads
		val shortRead1
		val shortRead2
		val longRead
	
	output:
		stdout
	
	script:
		"""

		quast ${contigs} -o ${output} -t ${Threads} -1 ${shortRead1} -2 ${shortRead2} --nanopore ${longRead}
		
		"""
}

process blast1 {
	publishDir "${params.output}/blast_results"
	
	input:
		val Threads
		file data
		val output
		val refbase
		val alignment
		val maxseqs
	
	output: 
		stdout
	
	script:
		"""
		module load swset/2018.05
		module load gcc/7.3.0
		module load blast-plus/2.10.0-py27
		
		blastn -num_threads "${Threads}" -query "${data}" -out "${output}" -db "${refbase} -outfmt "${alignment} -max_target_seqs "${maxseqs}"
		"""
}

process blast2 {
	publishDir "${params.output}/blast_results"
	
	input:
		val Threads
		file data2
		val output
		val refbase
		val alignment
		val maxseqs

	output:	
		
		stdout

	script:
	"""
		module load swset/2018.05
		module load gcc/7.3.0
		module load blast-plus/2.10.0-py27
		
		blastn -num_threads "${Threads}" -query "${data2}" -out "${output}" -db "${refbase}" -outfmt "${alignment}" -max_target_seqs "${maxseqs}" 
		"""
}

process barrnap {
	publishDir "${params.output}/barrnap_results"
	
	input:
		val kingdom
		val Threads
		path data
		val output_data
	
	output:
		path("RNA.out"), emit: barrnap_output
	
	script:
		"""
		module load miniconda3
		conda activate /pfs/tc1/project/arcc-students/bio2
		
		barrnap -k ${kingdom} -t ${Threads} --incseq ${data} --outseq ${output_data}
		"""
}

process foo {
	input:
		path x
	
	output:	
		path "./RNA.out", emit: RNA_output_edit

	script:
		'''
		awk 'NR==1{printf $0"\\t";next}{printf /^>/ ? "\\n"$0"\\t" : $0}' ${x} \\| awk -F"\\t" | awk -F"\\t" '{gsub("^>","",$0);print $0; exit}' > 16S.fasta
		'''
}
process fastani {
	publishDir "${params.output}/fastani_results"

	input:
		val Threads
		file data
		path reference_genomes
		val output_file

	script:
		"""
		module load miniconda3
		conda activate /pfs/tc1/project/arcc-students/bio2
		
		fastANI -t ${Threads} -q ${data} --rl ${reference_genomes} -o ${output_file}
		"""
}
/** ************************************************************************************************************************************************* */

workflow {
	uncomFiles = channel.fromPath (params.uncompressed) 
	fastqcRun(uncomFiles) 

	TrimSequences_PE (params.Threads, params.Read_1, params.Read_2, params.samplename, params.headcrop, params.trailing, params.minlenPE) 
	TrimSequences_SE (params.Threads, params.longread, params.samplename, params.minlenSE) 
	Unicycler_Hybrid_Assembly (TrimSequences_PE.out[0], TrimSequences_PE.out[1], TrimSequences_SE.out[0], params.Threads, params.output) 
	quastRun (Unicycler_Hybrid_Assembly.out.contigs, params.output, params.Threads, params.Read_1, params.Read_2, params.longread) 
	blast1 (params.Threads, Unicycler_Hybrid_Assembly.out.contigs, params.blast_result_1, params.database1, params.format1, params.maxseqs1) 
	 fastani (params.Threads, Unicycler_Hybrid_Assembly.out.contigs, params.ref_genome, params.fastani_output_file) 
	
	barrnap (params.kingdom, params.Threads, Unicycler_Hybrid_Assembly.out.contigs, params.barrnap_output_file) 
	foo (barrnap.out.barrnap_output)
	blast2 (params.Threads, foo.out.RNA_output_edit, params.blast_result_2, params.database1, params.format1, params.m
axseqs1) 
	}
