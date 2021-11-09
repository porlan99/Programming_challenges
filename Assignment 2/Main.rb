#Assignment 2 Bioinformatics Programming Challenges
#Antonio Porlán Miñarro
#Main.rb

#Requires
require 'json'
require 'rest-client'
require './Class_Genes.rb'

#ARGV
#file = ARGV[0]
report = ARGV[1]

#SET THE THRESHOLD
threshold = 0.485

#RUN THE FUNCTIONS
#Genes.read_file                      It is not neccesary because it is called in the next function
Genes.genes_interactors(threshold)     #It is not neccesary because it is called in the next function (IT IS CALLED TO OBTAIN A REPORT FILE)
#Genes.get_networks(threshold)        #THIS ONE IS NECCESARY TO BE RUN
#Genes.go_annotation(gene)            It is not neccesary because it is called in the next function
#Genes.kegg_annotation(gene)          It is not neccesary because it is called in the next function
#Genes.introduce(genes)               #THIS ONE IS NECCESARY TO BE RUN TOO

#REPORT DESIGN
File.open(report, 'w+') do |write|
  write.puts "ASSIGNMENT 2: INTENSIVE INTEGRATION USING WEB APIS by Antonio Porlan Miñarro\n"
  #write.puts "#{@@genes.count} genes have been analysed"
  write.puts "Interactions between genes of this list have been analysed, but doe to an error in the code it was not possible to get the result."
  write.puts "However, a simulation of the code has been uploaded to the assignment"
  write.puts "In case the code had been correctly created, this report would show the results of the analysis, which include genes interactions, number of total networks, kegg and go annotation\n"
  write.puts "Sorry for not getting the correct output"
end
