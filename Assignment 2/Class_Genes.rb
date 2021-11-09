#Assignment 2 Bioinformatics Programming Challenges
#Antonio Porlán Miñarro
#Class_Genes.rb

#Requires
require 'json'
require 'rest-client'

#Create the Class Genes with the genes of the list
class Genes
    
  attr_accessor :gene_ID  #genes
  attr_accessor :kegg     #kegg annotation
  attr_accessor :go       #go annotation
  attr_accessor :interactors  #network of interaction of that gene
  
  @@nets = 0              #number of total networks
  @@genes = []            #all the genes (initial list and no list)
  @@interactions = []     #all the interactions between genes
 
  #Initialize function
  def initialize (params = {})
    
    @gene_ID = params.fetch(:gene_ID, 'Unknown')
    @kegg = params.fetch(:kegg, 'Unknown')   
    @go = params.fetch(:go, 'Unknown')       
    @interactors = params.fetch(:network, 0)
    
  end

  #Function to capture the file
  def self.read_file
   
    #ARGV to capture the file with the list of genes (ArabidopsisSubNetwork_GeneList.txt)
    file = ARGV[0]
    #puts file
    
    #Read the file by the rows
    lines = File.readlines(file)
    #puts lines
    
    #Create a list with the genes
    genes = []
    
    #For each gen
    lines.each do |line|
      #lower case letters to avoid problems
      gene = line.downcase
      #eliminate "\n"
      gene = gene.delete("\n")
      #Add gene to the list
      genes.append(gene)
      #puts gene[-1]
    end
    
    #Check that the list has been correctly created
    #puts genes
    @@genes.append(genes)
    #puts @@genes
    #puts genes
    return genes #genes of the initial list
   
  end
 
  #Fetch function
  def self.fetch(url, headers = {accept: "*/*"}, user = "", pass="")
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
 
  #Function to capture the interactions given a score threshold
  def self.genes_interactors(threshold)
    #Call the function to create the list
    genes = Genes.read_file
    puts genes.count
    #Create a Hash with the genes of the list and their interactors
    interactors = Hash.new
    #counter to check the errors (it was not enough, I could not identify an error)
    n= 0
    #For each gene of the list of genes
    genes.each do |gene|
      
      #Create a list with the genes that interact with the gene of my list
      int_genes = []
      #Capture the URL
      res = Genes.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/query/#{gene}/?format=tab25")
      if res  # res is either the response object (RestClient::Response), or false, so you can test it with 'if'
        
        body = res.body  # get the "body" of the response
        puts body        #IT PUTS NOTHING, I DO NOT KNOW WHERE IS THE PROBLEM. I COULD NOT PROGRESS.
        n +=1            #Checkpoint
        interactions = body.split("\n")         #each interaction in the web is separated by "\n"
        puts interactions
        #for each interaction of that gene
        interactions.each do |int|
          n +=1           #Checkpoint (Does not work)
          puts "a"        #Checkpoint (Does not work)
          elements = int.split("\t")            #each element of the interaction is separated by "\t"
          #we can find both genes (which takes part in the interaction) in columns 3 and 4
          gen1 = elements[2].sub(/tair:/, "")   #delete the part that does not corresponde to the gene name
          gen2 = elements[3].sub(/tair:/, "")   #delete the part that does not corresponde to the gene name
          gen1 = gen1.downcase                  #gene name in lower case letter, the same as in the list of genes
          gen2 = gen2.downcase                  #gene name in lower case letter, the same as in the list of genes
          score = elements[14].sub(/intact-miscore:/, "") #capture the score of the interaction
          score = score.to_f                              #convert the score to float
                   
          if score >= threshold   #if the interaction has an score larger than the threshold
            if (elements[9].match(/taxid:3702/)) && (elements[10].match(/taxid:3702/))  #Filter to Arabidopsis Thaliana
              if gen1 == gen2       #if the gene which interacts is the same gene, next
                next
              else                        #if the genes which takes part in the interaction are different
                if gen1 == gene           #if gene1 is the gene of my list, the one which interacts with it is gene2
                  int_genes.append(gene2) #Add gene2 (interactor) to the list of interactors
                  @@genes.append(gene2)   #Add gene2 to the total of genes involved in interactions
                elsif gen2 == gene        #if gene2 is the gene of my list, the one which interacts with it is gene1
                  int_genes.append(gene1) #Add gene1 (interactor) to the list of interactors
                  @@genes.append(gene1)   #Add gene1 to the total of genes involved in interactions
                end
              end
            end
          end
        end
        
        #Add an entry in the hash for the interactors of that gene
        interactors[gene] = int_genes
        
      #If any error with the URL
      else
        puts "the Web call failed - see STDERR for details..."
      end
    
    puts n  #Checkpoint
    #Return the Hash with contains the genes of the list and its interactors
    puts interactors #Checkpoint
    return interactors
    end
  end
  
  #Function to get the interactions
  def self.get_networks(threshold)
    #Run the function to obtain the interactors
    interactors = Genes.genes_interactors(threshold) #SET THE THRESHOLD
    #For each gene of the initial list, take its interactors
    @@genes.each do |gene1|
      gene1_int = interactors[gene1]    #interactors of gene1 from the Hash
      #For each interactor, take its interactors.
      gene1_int.each do |gene2|         #interactors of gene2
      #But there are 2 possible scenarios:
        case
          when gene2.include?(@@genes)               #if gene2 is in our list of genes
            gene2_int = interactors[gene2]           #interactors of gene2 from the Hash
            
            gene2_int.each do |gene3|
              if (gene3.include?(@@genes)) && (gene1 != gene3)     #if gene is in our list of genes and is different to gene1
                new_net = [gene1, gene2, gene3]                    #network is composed by the 3 genes
                @@interactions.append(new_net)                     #add the new network 
                @@nets += 1                                        #1 network more added to the total
              end
            end
            
          else                                       #when the gene2 is not in our list
            #Capture again the URL
            res = Genes.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/query/#{gene2}/?format=tab25")
            if res  # res is either the response object (RestClient::Response), or false, so you can test it with 'if'
              body = res.body  # get the "body" of the response
              interact_genes = []                     #list of genes that interact with gene2
              interactions = body.split("\n")         #each interaction in the web is separated by "\n"
              #for each interaction of that gene
              interactions.each do |int|
                elements = int.split("\t")            #each element of the interaction is separated by "\t"
                #we can find both genes (which takes part in the interaction) in columns 3 and 4
                gen1_int = elements[2].sub(/tair:/, "")   #delete the part that does not corresponde to the gene name
                gen2_int = elements[3].sub(/tair:/, "")   #delete the part that does not corresponde to the gene name
                gen1_int = gen1_int.downcase                  #gene name in lower case letter, the same as in the list of genes
                gen2_int = gen2_int.downcase                  #gene name in lower case letter, the same as in the list of genes
                score_int = elements[14].sub(/intact-miscore:/, "") #capture the score of the interaction
                score_int = score_int.to_f                              #convert the score to float
                
                if score_int >= threshold                  #if the interaction has an score larger than the threshold
                  if (elements[9].match(/taxid:3702/)) && (elements[10].match(/taxid:3702/))  #Filter to Arabidopsis Thaliana
                    if gen1_int == gen2_int                #if the gene which interacts is the same gene, next
                      next
                    else                                   #if the genes which takes part in the interaction are different
                      if gen1_int == gene2                 #if gene1 is the gene of my list, the one which interacts with it is gene2
                        interact_genes.append(gene2_int)   #Add gene1 (interactor) to the list of interactors
                      elsif gen2_int == gene2              #if gene2 is the gene of my list, the one which interacts with it is gene1
                        interact_genes.append(gene1_int)   #Add gene1 (interactor) to the list of interactors
                      end
                    end
                  end
                end
              end
              
              #Now, I create the network of gene1 (in the list), gene2 (out of the list) and gene3 (which has to be again in the list)
              #For each interactors of gene2
              interact_genes.each do |gene3_int|
                if (gene3_int.include?(@@genes)) && (gene1 != gene3_int)    #if gene3 is in out list and is different to gene1, I add the network
                  new_net = [gene1, gene2, gene3_int]                       #network is composed by the 3 genes
                  @@interactions.append(new_net)                            #add the new network 
                  @@nets += 1                                               #1 network more added to the total
                end
                
              end
            end          
        end
      end
    end
  end
  
  #Define function to the kegg annotation of the genes
  def kegg_annotation(gene)       #gene would be each gene in @@genes in this case
    kegg_annotations = Hash.new   #Hash to introduce the annotations
    response = Genes.fetch("http://togows.org/entry/kegg-genes/ath:#{gene}/pathways.json")     
    if response  #If the web exists
      data = JSON.parse(response.body)[0] #[0] because JSON format is a list and I take the first object
      #For each feature of the gene I add it to the Hash
      data.each do |id, path|         #Capture the id and the path
        kegg_annotations[id] = path   #Add the entry to the Hash
      end        
    end
  end
  
  #Define function to the go annotation of the genes
  def go_annotation(gene)       #gene would beeach gene in @@genes in this case
    go_annotations = Hash.new   #Hash to introduce the annotations
     response = Genes.fetch("http://togows.org/entry/ebi-uniprot/#{gene}/dr.json")
     if response  #If the web exists
       data = JSON.parse(response.body)[0]["GO"] #[0] because JSON format is a list and I take the first object
                                                 #["GO"] to access to GO terms
       #for each feature of the gene I add it to the Hash
       data.each do |go_data|
         if go_data[1].match(/^P:/)     #We do the logical expression to capture only those which give info about the biological processes (starts with "P:")
           id = go_data[0]              #Capture the GO id
           path = go_data[1]            #Capture the path in which the gene is involved         
           go_annotations[id] = path    #Add it to the Hash
         end  
       end
     end
  end
  
  #Function to introduce the attributes in the class
  def self.introduce(gene_list)
    gene_list.each do |gene|
      gene = Genes.new(                     #Add the gene to the class Genes
        :gene_ID => gene,                   #Add gene name
        :kegg => kegg_annotation(gene),     #Add kegg annotation
        :go => go_annotation(gene),         #Add go annotation
        :interactors => interactors[gene]   #Add interactors of the gene
        )
    end
  end
  
  #It would be the line to introduce the attributes of the class 
  Genes.introduce(@@genes)
  
end

#CHECKPOINTS
#puts Genes.read_file
#puts Genes.genes_interactors(0)
#puts Genes.get_networks(0)