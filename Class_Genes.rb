#Assignment 2 Bioinformatics Programming Challenges
#Antonio Porlán Miñarro
#Class_Genes.rb

#Requires
require 'json'
require 'rest-client'

#we create  the class networks
class Genes
    
  attr_accessor :gene_ID  #genes
  attr_accessor :kegg     #kegg annotation
  attr_accessor :go       #go annotation
  
  @@nets = 0                    #number of total networks
  @@genes = []                  #genes of the initial list
  @@all = 0                     #number of genes that take part in the networks of 3 genes
  @@interactions = Hash.new     #all the interactions between genes
  @@networks = []               #all the networks of 3 genes
  @@net_genes = []              #genes that take part in the networks of 3 genes
 
  #Initialize function
  def initialize (params = {})
    
    @gene_ID = params.fetch(:gene_ID, 'Unknown')
    @kegg = params.fetch(:kegg, 'Unknown')   
    @go = params.fetch(:go, 'Unknown')       
    
  end
    
    #Functions to get this attributes out of the Class
    def self.genes      
        return @@genes
    end
    
    def self.nets_genes      
        return @@net_genes
    end
    
    def self.all      
        return @@all
    end
    
    def self.networks      
        return @@networks
    end
    
    def self.nets_n      
        return @@nets
    end   
    
    #Obtain the genes from the file and capture them
    def self.read_file(filename)
        @@genes = []                                #Create the list and add the genes to the list
        File.foreach(filename) do |line|
            @@genes.append(line.strip.downcase) 
        end
    end
    
    #Create fetch function
    def self.fetch(url,headers = {accept: "*/*"}, user = "",pass= "")
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

        #For every gene in the list
        @@genes.each do |gene|
            #Create a list with the genes that interact with the gene of my list
            int_genes = []
            #Capture the URL
            res = Genes.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{gene}/?format=tab25")
            # we test if the response of the function is correct
            if res
                body = res.body
                #we do this beacuse maybe there are multiples interactors of the gene that we are looking for
                interactions = body.split("\n")
                #For every interaction
                interactions.each do |int|
                    elements = int.split("\t")                      #each element of the interaction is separated by "\t"
                    #we can find both genes (which takes part in the interaction) in columns 3 and 4
                    gene1 = elements[2].sub(/tair:/, "")            #delete the part that does not corresponde to the gene name
                    gene2 = elements[3].sub(/tair:/, "")            #delete the part that does not corresponde to the gene name
                    gene1 = gene1.downcase                          #gene name in lower case letter, the same as in the list of genes
                    gene2 = gene2.downcase                          #gene name in lower case letter, the same as in the list of genes
                    score = elements[14].sub(/intact-miscore:/, "") #capture the score of the interaction
                    score = score.to_f                              #convert the score to float
                    if score >= threshold                           #if the interaction has an score larger than the threshold
                      #Results obtained: 831
                      if (elements[9].match(/taxid:3702/)) && (elements[10].match(/taxid:3702/))  #Filter to Arabidopsis Thaliana (it does not eliminate any interaction)
                        if gene1 == gene2            #if the gene which interacts is the same gene, next
                          #Results obtained: 10
                          next
                        else                         #if the genes which takes part in the interaction are different
                          #Results obtained: 821
                          if gene1 == gene           #if gene1 is the gene of my list, the one which interacts with it is gene2
                            #Results obtained: 409
                            int_genes.append(gene2)  #Add gene2 (interactor) to the list of interactors
                          elsif gene2 == gene        #if gene2 is the gene of my list, the one which interacts with it is gene1
                            #Results obtained: 412
                            int_genes.append(gene1)  #Add gene1 (interactor) to the list of interactors
                          end
                        end
                      end
                    end
                end
                
                #Add an entry in the hash for the interactors of that gene
                @@interactions[gene] = int_genes
            #If any error with the URL
            else
              puts "the Web call failed - see STDERR for details..."
            end
                     
        end
            
    end

    
    
  #Function to get the interactions
  def self.get_networks(threshold)
    #For each gene of the initial list, take its interactors
    @@genes.each do |gene1|
      gene1_ints = @@interactions[gene1]                          #interactors of gene1 from the Hash
      #For each interactor, take its interactors.
      gene1_ints.each do |gene2|                                  #interactors of gene2
      #But there are 2 possible scenarios:
        case
          when @@genes.include?(gene2)                            #if gene2 is in our list of genes
            gene2_ints = @@interactions[gene2]                    #interactors of gene2 from the Hash
            
            gene2_ints.each do |gene3|
              if (@@genes.include?(gene3)) && (gene1 != gene3)     #if gene is in our list of genes and is different to gene1
                new_net = [gene1, gene2, gene3]                    #network is composed by the 3 genes
                @@networks.append(new_net)                         #add the new network 
                @@nets += 1                                        #1 network more added to the total
              end
            end                                                    #Results: 3 networks in which the 3 genes are in our initial list
            
          else                                                     #when the gene2 is not in our list
            #Capture again the URL
            res = Genes.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{gene2}/?format=tab25")
            if res  # res is either the response object (RestClient::Response), or false, so you can test it with 'if'
              body = res.body  # get the "body" of the response
              interact_genes = []                     #list of genes that interact with gene2
              interactions = body.split("\n")         #each interaction in the web is separated by "\n"
              #for each interaction of that gene
              interactions.each do |int|
                elements = int.split("\t")            #each element of the interaction is separated by "\t"
                #we can find both genes (which takes part in the interaction) in columns 3 and 4
                gene1_int = elements[2].sub(/tair:/, "")   #delete the part that does not corresponde to the gene name
                gene2_int = elements[3].sub(/tair:/, "")   #delete the part that does not corresponde to the gene name
                gene1_int = gene1_int.downcase                  #gene name in lower case letter, the same as in the list of genes
                gene2_int = gene2_int.downcase                  #gene name in lower case letter, the same as in the list of genes
                score_int = elements[14].sub(/intact-miscore:/, "") #capture the score of the interaction
                score_int = score_int.to_f                              #convert the score to float
                
                if score_int >= threshold                  #if the interaction has an score larger than the threshold
                  if (elements[9].match(/taxid:3702/)) && (elements[10].match(/taxid:3702/))  #Filter to Arabidopsis Thaliana
                    if gene1_int == gene2_int                #if the gene which interacts is the same gene, next
                      next
                    else                                   #if the genes which takes part in the interaction are different
                      if gene1_int == gene2                #if gene1 is the gene of my list, the one which interacts with it is gene2
                        interact_genes.append(gene2_int)   #Add gene1 (interactor) to the list of interactors
                      elsif gene2_int == gene2             #if gene2 is the gene of my list, the one which interacts with it is gene1
                        interact_genes.append(gene1_int)   #Add gene1 (interactor) to the list of interactors
                      end
                    end
                  end
                end
              end
              
              #Now, I create the network of gene1 (in the list), gene2 (out of the list) and gene3 (which has to be again in the list)
              #For each interactors of gene2
              interact_genes.each do |gene3_int|
                if (@@genes.include?(gene3_int)) && (gene1 != gene3_int)    #if gene3 is in out list and is different to gene1, I add the network
                  new_net = [gene1, gene2, gene3_int]                       #network is composed by the 3 genes
                  @@networks.append(new_net)                                #add the new network 
                  @@nets += 1                                               #1 network more added to the total
                end
                
              end
            end          
        end
      end
    end  
  end
  
  #Define function to the go annotation of the genes
  def self.go_annotation(gene)       #gene would be each gene in @@genes in this case
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
     return go_annotations
  end
    
  
  #Define function to the kegg annotation of the genes
  def self.kegg_annotation(gene)       #gene would be each gene in @@genes in this case
    kegg_annotations = Hash.new        #Hash to introduce the annotations
    response = Genes.fetch("http://togows.org/entry/kegg-genes/ath:#{gene}/pathways.json")     
    if response  #If the web exists
      data = JSON.parse(response.body)[0] #[0] because JSON format is a list and I take the first object
      #For each feature of the gene I add it to the Hash
      data.each do |id, path|         #Capture the id and the path
        kegg_annotations[id] = path   #Add the entry to the Hash
      end        
    end
    return kegg_annotations
  end
  
  
  #Function to keep only the genes that take part into the networks in order to obtain just their annotation. Objective: optimization.
  def self.net_genes(networks)
    networks.each do |net|             #for each network created
      net.each do |gene|               #for each gene of the net
        if @@net_genes.include?(gene)  #if the gene is already in the list, next
          next
        else                           #if the gene is not in the list, I add it 
          @@net_genes.append(gene)
          @@all += 1
        end  
      end
    end
  end  
  
  
  #Function to introduce the attributes in the class
  def self.introduce(gene_list)
    gene_list.each do |gene|
      gene = Genes.new(                          #Add the gene to the class Genes              
        :gene_ID => gene,                        #Add gene name
        :kegg => self.kegg_annotation(gene),     #Add kegg annotation
        :go => self.go_annotation(gene)          #Add go annotation
        )
    end
  end
       
end