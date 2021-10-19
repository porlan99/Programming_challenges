##Creating Class 3

class Cross
  
  attr_accessor :parent1
  attr_accessor :parent2
  attr_accessor :f2_wild
  attr_accessor :f2_p1 
  attr_accessor :f2_p2
  attr_accessor :f2_p1p2
  attr_accessor :total #new attribute with the total of f2 indvividuals in each cross
  attr_accessor :e_f2_wild #new: expected f2 wild
  attr_accessor :e_f2p1_or_f2p2 #new: expected f2p1 or f2p2
  attr_accessor :e_f2p1p2 #new: expected f2p1p2
  
  def initialize (params = {})
    
    @parent1 = params.fetch(:parent1, 'X000')
    @parent2 = params.fetch(:parent2, 'X000')
    @f2_wild = params.fetch(:f2_wild, 0)
    @f2_p1 = params.fetch(:f2_p1, 0)
    @f2_p2 = params.fetch(:f2_p2, 0)
    @f2_p1p2 = params.fetch(:f2_p1p2, 0)
    @total = params.fetch(:total, 0) #new attribute with the total on indv
    @e_f2_wild = params.fetch(:e_f2_wild, 0) #new attribute
    @e_f2p1_or_f2p2 = params.fetch(:e_f2p1_or_f2p2, 0) #new attribute
    @e_f2p1p2 = params.fetch(:e_f2p1p2, 0) #new attribute
    
  end

end

#Capture the file
file3_root = "/home/osboxes/Desktop/Programming_Task1_databases/cross_data.tsv"
#Read the file by the rows
lines = File.readlines(file3_root)

#Number of lines
nlines = lines.count
rangelines = 0..(nlines-1)

#Create an array with the object names
class_names = Array.new([])

#For each line
rangelines.each do |x|
  #If it is header line, next
  next if x == 0
  #Create a new name
  c_name = "c"+ x.to_s
  #Add object name to the array
  class_names.append(c_name)
  #Catch the attributes and add it to the class Stock
  elements = lines[x].split("\t")
  
  
  #Add it to the class Cross
  class_names[x-1] = Cross.new(
    :parent1 => elements[0],
    :parent2 => elements[1],
    :f2_wild => elements[2].to_f,
    :f2_p1 => elements[3].to_f,
    :f2_p2 => elements[4].to_f,
    :f2_p1p2 => elements[5].to_f,
    :total => (elements[2].to_f + elements[3].to_f + elements[4].to_f + elements[5].to_f),
    :e_f2_wild => ((elements[2].to_f + elements[3].to_f + elements[4].to_f + elements[5].to_f) * 9/16), #9/16 is the expected frequency for f2 wild type
    :e_f2p1_or_f2p2 => ((elements[2].to_f + elements[3].to_f + elements[4].to_f + elements[5].to_f) * 3/16), #3/16 is the expected frequency for both f2 p1 or p2 mutant
    :e_f2p1p2 => ((elements[2].to_f + elements[3].to_f + elements[4].to_f + elements[5].to_f) * 1/16) #1/16 is the expected frequency for f2 with both p1 and p2 mutations
    )

end

#Taking into account p-value and degrees of freedom we set the Chi**2 value
#set the p-value to 0.05
#DF = 3 because there are 4 posible options, so 4-1=3 degrees of freedom
#Considering this information:
chi2 = 7.815

#Calculate Chi**2 for each couple of genes
  #USED FORMULA 
  #Chi**2 = Σ(Oi-Ei)**2/Ei
    #Being:
    # -Oi:observed values
    # -Ei:expected values
    
#Calculate Chi**2 value for each cross
class_names.each do |x|
  value = ((x.f2_wild - x.e_f2_wild)**2/x.e_f2_wild) +
  ((x.f2_p1 - x.e_f2p1_or_f2p2)**2/x.e_f2p1_or_f2p2) +
  ((x.f2_p2 - x.e_f2p1_or_f2p2)**2/x.e_f2p1_or_f2p2) +
  ((x.f2_p1p2 - x.e_f2p1p2)**2/x.e_f2p1p2)
  
  #If calculated value is bigger than chi**2, they are linked
  if value > chi2
    puts "#{x.parent1} is genetically linked to #{x.parent2} with chisquare score #{value}"
  end
end       