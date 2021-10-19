##Creating Class 2

class Info
  
  attr_accessor :gene_ID
  attr_accessor :gene_name
  attr_accessor :mutant_pheno

  def initialize (params = {})
    
    @gene_ID = params.fetch(:gene_ID, 'AT0G00000')
    @gene_name = params.fetch(:gene_name, 'some_name')
    @mutant_pheno = params.fetch(:mutant_pheno, 'some_pheno')
  
  end
  
end

#Capture the file
file2_root = "/home/osboxes/Desktop/Programming_Task1_databases/gene_information.tsv"
#Read the file by the rows
lines = File.readlines(file2_root)

#Number of lines
nlines = lines.count
rangelines = 0..(nlines-1)

#Create an array
class_names = Array.new([])

#For each line
rangelines.each do |x|
  #If it is header line, next
  next if x == 0
  
  #Create a new name
  i_name = "i"+ x.to_s
  #Capture the names of the objects
  class_names.append(i_name)
  
  #Catch the elements and add it to the attributes of the class Stock
  elements = lines[x].split("\t")
  
  #Add it to the class Info
  class_names[x-1] = Info.new(
    :gene_ID => elements[0],
    :gene_name => elements[1],
    :mutant_pheno => elements[2]
    )

end