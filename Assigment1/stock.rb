##Creating Class 1
require 'date'

class Stock
  
  attr_accessor :seed_stock
  attr_accessor :mutant_ID
  attr_accessor :last_planted
  attr_accessor :storage 
  attr_accessor :grams_remain

  def initialize (params = {})
    
    @seed_stock = params.fetch(:seed_stock, 'Some_Stock')
    @mutant_ID = params.fetch(:mutant_ID, 'AT0G00000')
    @last_planted = params.fetch(:last_planted, '00/00/0000')
    @storage = params.fetch(:storage, 'camaX')
    @grams_remain = params.fetch(:grams_remain, 0)
    
  end
  
  #Function to calculate the remaining seeds
  def remaining_seeds(grams_planted)
    #Substract grams planted of seeds
    @grams_remain = @grams_remain - grams_planted
    #DateTime from Mark
    @last_planted = DateTime.now.strftime('%-d/%-m/%Y') # https://ruby-doc.org/stdlib-1.9.3/libdoc/date/rdoc/DateTime.html

    
    #Warning message if run out of seeds and set quantity to 0 because it is not posible to set a negative quantity
    if @grams_remain <= 0
      @grams_remain = 0
      puts "WARNING: we have run out of Seed Stock #{@seed_stock}"
    
    end
    
  end 
  
end

#Capture the file
file1_root = "/home/osboxes/Desktop/Programming_Task1_databases/seed_stock_data.tsv"
#Read the file by the rows
lines = File.readlines(file1_root)

#Check the rigth reading file step
#lines.each do |line|
#  puts line
#end

#Number of lines
nlines = lines.count
rangelines = 0..(nlines-1)
#puts rangelines

#Create an array for names to introduce in the class
class_names = Array.new([])

#Create an array for elements
#class_elements = {}

#Catch header line
header = lines[0]

#For each line
rangelines.each do |x|
  #If it is header line, next
  next if x == 0
  
  #Create a new name
  p_name = "p"+ x.to_s
  
  #Add the new name (objetc) to the list
  class_names.append(p_name)
    
  #Catch the attributes and add it to the class Stock
  elements = lines[x].split("\t")
    
  #Add it to the class Stock
  class_names[x-1] = Stock.new(
    :seed_stock => elements[0],
    :mutant_ID => elements[1],
    :last_planted => elements[2],
    :storage => elements[3],
    :grams_remain => elements[4].to_f
    )

end

#puts class_names[0].seed_stock
#puts class_elements

#Use the function to substract 7 grams from each stock
class_names.each do |seed|
  seed.remaining_seeds(7.0)
end

#Create new_stock_file.tsv
out = File.new("new_stock_file.tsv", "w")
#counter variable to introduce the header
counter = 0
#each loop to introduce the lines of the new file
class_names.each do |name|
  #if first line, introduce header first and line after
  if counter == 0
    #chenge the counter variable
    counter += 1
    #fill the new file
    out.puts(header)
    out.puts(name.seed_stock + "\t" + name.mutant_ID + "\t" + name.last_planted + "\t" + name.storage + "\t" + name.grams_remain.to_i.to_s + "\n")
  else
    out.puts(name.seed_stock + "\t" + name.mutant_ID + "\t" + name.last_planted + "\t" + name.storage + "\t" + name.grams_remain.to_i.to_s + "\n")
  end
end

