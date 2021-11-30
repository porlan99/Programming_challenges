#Assignment 3 Bioinformatics Programming Challenges
#Antonio Porlán Miñarro
#Assignment3.rb


#Requires
require 'rest-client'
require 'bio'

#Create fetch function
def fetch(url,headers = {accept: "*/*"}, user = "",pass= "")
    response = RestClient::Request.execute({
        method: :get,
        url: url.to_s,
        user: user,
        password: pass,
        headers: headers})
    return response
        
    rescue RestClient::ExceptionWithResponse => e
        $stderr.puts e.inspect
        response = false
        return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue RestClient::Exception => e
        $stderr.puts e.inspect
        response = false
        return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue Exception => e
        $stderr.puts e.inspect
        response = false
        return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
end

#Create function to capture the website
def genes_hash(filename)
  #HASH
  #Key: gene names
  #Value: Bio::EMBL object
  embl_info = Hash.new                #Hash to capture the Bio::EMBL object of each gene
  #For every gene in the list
  File.foreach(filename) do |line|
    line = line.strip
    #Capture the URL
    res = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{line}")
    if res
      body = res.body
      entry = Bio::EMBL.new(body)
      embl_info[line] = entry         #Save the entry in the hash
    end  
  end
  return embl_info                    #Return the hash
end


#Function to capture the features of the exons
def ex_feats(position, seq, strand)
  feature = Bio::Feature.new("repeated_sequence", position)       #Create Bio::Feature object with "feature" and "position"
  feature.append(Bio::Feature::Qualifier.new("seq", seq))         #Add Qualifier: the sequence searched
  feature.append(Bio::Feature::Qualifier.new("strand", strand))   #Add Qualifier: the strand ("+" or "-")
end

#Function to search for the exons
def exons(embls)
  
  #Hash to capture the coordinates
  #Key: gene name
  #Value: coordinates where the sequence is (in exons)
  coords = Hash.new
  
  #Hash to capture the biosequence objects
  #Key: gene name
  #Value: features of the repetitions found
  bios = Hash.new
  
  #The sequence searched (in both strands)
  seq = Bio::Sequence::NA.new("CTTCTT").to_re
  seq_comp = Bio::Sequence::NA.new("AAGAAG").to_re
  
  #for each entry (gene) of the hash (with values as database entry)
  embls.each do |gene, embl|                #take the gene name and the value
    coord = Array.new                       #Array with the exon coordinates of each gene 
    bioseq = embl.to_biosequence            #this is how you convert a database entry to a Bio::Sequence
    #for each feature of the Bio::Sequence
    feats = embl.features                   #Obtain the features
    feats.each do |feat|                    #for each feature
      #When it correspond to the exon
      if feat.feature == "exon"              
        locs = feat.locations               #capture the locations
        #for each location found
        locs.each do |loc|                  
          start = loc.from.to_i             #capture the start of the sequence
          fin = loc.to.to_i                 #capture the end of the sequence
          exon_seq = embl.seq[start..fin]   #define the sequence of the exon
          #if there is something in the sequence of the exon
          if exon_seq != nil                
            strand = loc.strand             #capture the strand
            #if it is the strand "+"
            if strand == 1
              #if the sequence is in the exon sequence
              if exon_seq.match(seq)
                pos = "#{exon_seq.match(seq).begin(0)+1}..#{exon_seq.match(seq).end(0)}" #capture the position of the sequence in the exon
                next if coord.include?(pos)                                              #Avoid repeated 
                coord.append(pos)                                                        #Add coordinate to the array
                bioseq.features << ex_feats(pos, "CTTCTT", "+")                          #Add features to the Bio::Sequence object
                bios[gene] = bioseq                                                      #Add the object to the hash
              end
            #if it is the strand "-"  
            elsif strand == -1
              #if the sequence is in the exon sequence
              if exon_seq.match(seq_comp)
                pos = "#{exon_seq.match(seq_comp).begin(0)}..#{exon_seq.match(seq_comp).end(0)-1}" #capture the position of the sequence in the exon
                next if coord.include?(pos)                                                        #Avoid repeated
                coord.append(pos)                                                                  #Add coordinate to the array
                bioseq.features << ex_feats(pos, "AAGAAG", "-")                                    #Add features to the Bio::Sequence object
                bios[gene] = bioseq                                                                #Add the object to the hash
              end
            end
          end
        end 
      end
    end
  #Capture the coordinates in the hash
  coords[gene] = coord
end
  #Return both Hashes
  return coords, bios
end

#Function to write the gff3-formated file with the features of each one
def write_first_gff3(file_name,bioseqs)
  #GFF3 DESIGN
  File.open(file_name, 'w+') do |write|         
  write.puts "##gff3-formated file with features of each repeated sequence with gene coordinates\n"
    #for each entrance of the hash, take the gene name and the Bio::Sequence object
    bioseqs.each do |gene, bioseq|
      n = 0                                          #counter for the number of repeated sequence in each gene
      feats = bioseq.features                        #capture the features
      #for every feature
      feats.each do |feat|
        #if it is the Bio::Feature that was created at the beginning
        if feat.feature == "repeated_sequence"
          n += 1                                     #counter
          strand = feat.assoc["strand"]              #get the hash with the qualifier objects
          position = feat.position                   #capture the position of the sequence in the gene
          start, fin = position.split("..")          #capture the start and the end of the sequence in the gene
          type = "dispersed_repeat"                  #set the column "type" based on the Sequence Ontology SOFA
          attributes = "ID=CCTCCT_exon_repetition_#{gene}_n#{n}"   #set the column "attributes" with an ID
          write.puts "#{gene}\t.\t#{type}\t#{start}\t#{fin}\t.\t#{strand}\t.\t#{attributes}" #write in gff3 format
        end  
      end
    end
  end
end

#Function to get the report of genes without CTTCTT repetitions in their exons
def no_rep_report(file_name, coordenates)
  #GFF3 DESIGN
  n = 0                                    #counter to count the number of genes
  File.open(file_name, 'w+') do |write|
    write.puts "ASSIGNMENT 3: GFF feature files and visualization by Antonio Porlan Miñarro\n"
    write.puts "\nNO REPEATED REPORT\n"
    write.puts "This report shows which genes do not have exons with the CTTCTT repeat\n"
    #for each gene take its name and coordinates where the repeated sequence is
    coordenates.each do |gene, coord|
      if coord == []                      #if there are no coordinates
        n += 1                            #counter
        write.puts "\n\t#{n}. #{gene}"    #annotate it in the report
      end  
    end
  end
end

#Function to write the gff3-formated file with the features in the chromosomes
def write_second_gff3(file_name,bioseqs)
  #GFF3 DESIGN
  File.open(file_name, 'w+') do |write|
  write.puts "##gff3-formated file with features of each repeated sequence with chromosome coordinates\n"
    #for each entrance of the hash, take the gene name and the Bio::Sequence object
    bioseqs.each do |gene, bioseq|
      n = 0                                          #counter for the number of repeated sequence in each gene
      feats = bioseq.features                        #capture the features
      #for every feature
      feats.each do |feat|
        #if it is the Bio::Feature that was created at the beginning
        if feat.feature == "repeated_sequence"
          n += 1                                                  #counter
          strand = feat.assoc["strand"]                           #get the hash with the qualifier objects
          chr_n = bioseq.primary_accession.split(":")[2]          #capture the chromosome number
          chr_position = bioseq.primary_accession.split(":")[3]   #capture the position in the chromosome
          position = feat.position                                #capture the position of the sequence in the gene
          start, fin = position.split("..")                       #capture the position of the sequence in the gene (start and end)
          #add the position of the gene in the chromosome plus the sequence in the gene to obtain the position of the sequence in the chromosome
          start_chr = chr_position.to_i + start.to_i              #capture the start position of the sequence in the chromosome
          fin_chr = chr_position.to_i + fin.to_i                  #capture the end position of the sequence in the chromosome
          type = "dispersed_repeat"                               #set the column "type" based on the Sequence Ontology SOFA
          attributes = "ID=CCTCCT_exon_repetition_#{gene}_n#{n}"  #set the column "attributes" with an ID
          write.puts "Chr#{chr_n}\t.\t#{type}\t#{start_chr}\t#{fin_chr}\t.\t#{strand}\t.\t#{attributes}" #write in gff3 format
        end  
      end
    end
  end
end


#ARGVs
filename = ARGV[0]      #file with the gene names
first_gff3 = ARGV[1]    #gff3 file created for coordinates in genes (first)
report = ARGV[2]        #report showing which genes do not have exons with the CTTCTT repeat
second_gff3 = ARGV[3]   #gff3 file created for coordinates in chromosomes (second)

#RUN THE FUNCTIONS
embl_info = genes_hash(filename)        #Obtain the Bio::EMBL objects of each gene
coords, bios = exons(embl_info)         #Obtain the repeated sequences coordinates in the gene and its features
write_first_gff3(first_gff3, bios)      #Obtain the first gff3 file
no_rep_report(report, coords)           #Obtain the report
write_second_gff3(second_gff3, bios)    #Obtain the second gff3 file