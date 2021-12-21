#Assignment 4 Bioinformatics Programming Challenges
#Antonio Porlán Miñarro
#Assignment4.rb

#Requires
require 'bio'

#Capture the files
AT_fa = ARGV[0]
SPAC_fa = ARGV[1]
report_name = ARGV[2]

#Save the captured files in Bio::FlatFile objects
AT = Bio::FlatFile.auto(AT_fa)
SPAC = Bio::FlatFile.auto(SPAC_fa)

#Create a directory to save the databases
system("mkdir Databases")
system("cp #{AT_fa} ./Databases/")
system("cp #{SPAC_fa} ./Databases/")

#Function to get the tipe of sequence (NA or AA)
def type_of_seq(flatobject)
  seq_entry = Bio::Sequence.auto(flatobject.next_entry.to_s)
    #The sequence can be of nucleotides or of aminoacids
    #If it is of nucleotides, save it
    if seq_entry.guess == Bio::Sequence::NA
      seq_type = 'nucl'
    #If it is of aminoacids, save it
    elsif seq_entry.guess == Bio::Sequence::AA
      seq_type = 'prot'
    end
    return seq_type
end
    
#Function to create a database with Bioruby
def create_db(flatobject, fastafile)
  #Capture the type of sequence
  seq_type = type_of_seq(flatobject) 
  #Create the database
  system("makeblastdb -in #{fastafile} -dbtype #{seq_type} -out ./Databases/#{fastafile}")
end

#Function: once I know the type of sequence, lets do de blast analysis
def blast_type(type1, type2)
  #If both are NA seqs, lets perform an blastn
  if type1 == 'nucl' && type2 == 'nucl'
    factory1 = Bio::Blast.local("blastn", "./Databases/#{AT_fa}")
    factory2 = Bio::Blast.local("blastn", "./Databases/#{SPAC_fa}")
  #If one is NA seq and the other AA seq, perform a tblast to NA->AA and blastx to AA->NA
  elsif type1 == 'nucl' && type2 == 'prot'
    factory1 = Bio::Blast.local("tblastn", "./Databases/#{AT_fa}")
    factory2 = Bio::Blast.local("blastx", "./Databases/#{SPAC_fa}")
  #If one is NA seq and the other AA seq, perform a tblast to NA->AA and blastx to AA->NA
  elsif type1 == 'prot' && type2 == 'nucl'
    factory1 = Bio::Blast.local("blastx", "./Databases/#{AT_fa}")
    factory2 = Bio::Blast.local("tblastn", "./Databases/#{SPAC_fa}")
  #If both are AA seqs, lets perform an blastp
  elsif type1 == 'prot' && type2 == 'prot'
    factory1 = Bio::Blast.local("blastp", "./Databases/#{AT_fa}")
    factory2 = Bio::Blast.local("blastp", "./Databases/#{SPAC_fa}")
  end
  return factory1, factory2
end

#Function to create hash to save the IDs and the sequences in each file
def idseq_hash(flatobject)
  #Create the new hash
  #Key:ID
  #Value:sequence
  new_hash = Hash.new
  #Add ids and seqs to the hash
  flatobject.each_entry do |entry|
    new_hash[entry.entry_id]=entry.seq
  end
  #Capture the file
  return new_hash
end

#Activate the functions
create_db(AT, AT_fa)
create_db(SPAC, SPAC_fa)

#In order to automate the script, lets consider the 4 possible alternatives: NA x NA, NA x AA, AA x NA, AA x AA.
#First, obtain and capture the type of both sequences
seq1_type = type_of_seq(AT)
seq2_type = type_of_seq(SPAC)

#Blast results
factory1, factory2 = blast_type(seq1_type, seq2_type)

#Hashes with:
  #Key:ID
  #Value:sequence
ATseqs = idseq_hash(AT)
SPACseqs = idseq_hash(SPAC)

#Create a list to capture the orthologues
orth = []

#INTRODUCE THE LIMITATIONS
e_value = 10**-6
#cover=0.5
 
#Counter for orthologues
c=0

#For every entrance of the hash created with ids and seqs
SPACseqs.each do |entry|
  #capture the id of the prot
  id_1 = entry[0]
  report2 = factory1.query(">myseq\n#{entry[1]}") #entry[1] corresponds to the sequence
  #If there are no hits, next
  next unless report2.hits.length != 0
  #If the e-value of the hit is not enough, next
  next unless report2.hits[0].evalue <= e_value
  
  ###This filter can be added too
  #q_end1 = report2.hits[0].query_end
  #q_start1 = report2.hits[0].query_start
  #quer1 = q_end1 - q_start1
  #next unless quer1 >= cover
  
  #Now, search for the reciprocal hit to confirm that they are orthologues
  #Capture the id of the other sequence
  id_2 = report2.hits[0].definition.split('|')[0].strip 
  #Repeat what was done before
  report1 = factory2.query(">myseq\n#{ATseqs[id_2]}")
  #If there are no hits, next
  next unless report1.hits.length != 0
  #If the e-value of the hit is not enough, next
  next unless report1.hits[0].evalue <= e_value
  
  ###This filter can be added too
  #q_end2 = report1.hits[0].query_end
  #q_start2 = report1.hits[0].query_start
  #quer2 = q_end2 - q_start2
  #next unless quer2 >= cover

  #If both hits are reciprocal, save these ids as orthologues
  if report1.hits[0].definition.split('|')[0].to_s.strip == entry[0]
    c+=1
    orth.append([id_1,id_2])
  end 
end

#REPORT DESIGN
n = 0                                    #counter to count the number of orthologs
File.open(report_name, 'w+') do |write|
  write.puts "ASSIGNMENT 4: Searching for Orthologues by Antonio Porlan Miñarro\n\n"
  write.puts "This report shows the couples of orthologues genes found in the analysis\n"
  write.puts "It contains a total of #{c} couples which have been obtained with a blast hit e-value threshold of #{e_value}.\n"
  write.puts "This value was obtained from the following paper:\n"
  write.puts "Moreno-Hagelsieb, Gabriel, and Kristen Latimer. “Choosing Blast Options for Better Detection of Orthologs as Reciprocal Best Hits.” "
  write.puts "OUP Academic, Oxford University Press, 26 Nov. 2007, https://doi.org/10.1093/bioinformatics/btm585\n"
  write.puts "\nThis step, the performance of Reciprocal-best-BLAST, is only an initial step in demonstrating that two genes are orthologues. "
  write.puts "In order to check that candidate gene couples are indeed orthologues, we could perform phylogenetic analyses, creating phylogenetic trees of homologous proteins in different evolutionarily close species and observe whether these proteins arise from a speciation event.\n"

  #For each couple of orthologues
  orth.each do |gene1, gene2|
    n += 1                                          #counter
    write.puts "\n\t#{n}. #{gene1} and #{gene2}"    #annotate it in the report
  end
end