#Assignment 2 Bioinformatics Programming Challenges
#Antonio Porlán Miñarro
#Main.rb

#Requires
require 'json'
require 'rest-client'
require './Class_Genes.rb'

#ARGV
file = ARGV[0]      #file given which contains the gene names
report = ARGV[1]    #report created with the information obtained in the analysis

#SET THE THRESHOLD (minimum score of the interaction between 2 genes to consider it as an interaction)
threshold = 0.485

#RUN THE FUNCTIONS
Genes.read_file(file)                     #Obtain the genes of the list
Genes.genes_interactors(threshold)        #Obtain the interactions 
Genes.get_networks(threshold)             #Obtain the networks
Genes.net_genes(Genes.networks)           #Obtain the genes that participate in the networks
Genes.introduce(Genes.nets_genes)         #Obtain the info of the genes that participate in the networks (objects and attributes)


#REPORT DESIGN
File.open(report, 'w+') do |write|
  write.puts "ASSIGNMENT 2: INTENSIVE INTEGRATION USING WEB APIS by Antonio Porlan Miñarro\n"
  write.puts "\nNETWORKS REPORT\n"
  write.puts "This report has information about gene interaction networks and the annotation of its members\n"
  write.puts "We have obtained #{Genes.nets_n} networks, composed by a total of #{Genes.all} different genes\n"
  write.puts "Bellow is an example of some of these networks and the kegg and go annotation of the genes that participate in them:\n\n"
  #We use just few examples because of the computational cost and the necessary time to do it
  #Example of 10 networks
  n = 0 #counter variable
  Genes.networks.each do |gene1, gene2, gene3|        #each gene of the network of 3 genes
    n += 1
    if n < 11 #If it is one of the 10 first networks I annotate it
      write.puts "\tNetwork #{n}\n\n"
      write.puts "Composed by #{gene1}, #{gene2}, and #{gene3}\n"
      write.puts "Their annotations are:\n "
      write.puts "\tFor #{gene1}:\n\t\tGO terms: #{Genes.go_annotation(gene1)}\n\t\tKEGG terms: #{Genes.kegg_annotation(gene1)}\n"
      write.puts "\tFor #{gene2}:\n\t\tGO terms: #{Genes.go_annotation(gene2)}\n\t\tKEGG terms: #{Genes.kegg_annotation(gene2)}\n"
      write.puts "\tFor #{gene3}:\n\t\tGO terms: #{Genes.go_annotation(gene3)}\n\t\tKEGG terms: #{Genes.kegg_annotation(gene3)}\n\n"     
      
    else
      break #if I have already written the 10 first networks, exit the each loop
    end  
  end
end
