# The MIT License
#
# Copyright (c) 2012 David Heitzman
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module GAHelloWorld
  RAND_SEED=srand
  TARGET_GENE= <<END
MACBETH: Is this a dagger which I see before me,
The handle toward my hand? Come, let me clutch thee!
I have thee not, and yet I see thee still.
Art thou not, fatal vision, sensible
To feeling as to sight? or art thou but
A dagger of the mind, a false creation
Proceeding from the heat-oppressèd brain?
I see thee yet, in form as palpable
As this which now I draw.
Thou marshall'st me the way that I was going,
And such an instrument I was to use.
Mine eyes are made the fools o' th' other senses,
Or else worth all the rest. I see thee still,
And on thy blade and dudgeon gouts of blood,
Which was not so before. There's no such thing.
It is the bloody business which informs
Thus to mine eyes. Now o'er the one half-world
Nature seems dead, and wicked dreams abuse
The curtained sleep. Witchcraft celebrates
Pale Hecate's offerings; and withered murder,
Alarumed by his sentinel, the wolf,
Whose howl 's his watch, thus with his stealthy pace,
With Tarquin's ravishing strides, towards his design
Moves like a ghost. Thou sure and firm-set earth,
Hear not my steps which way they walk, for fear
Thy very stones prate of my whereabout
And take the present horror from the time,
Which now suits with it. Whiles I threat, he lives;
Words to the heat of deeds too cold breath gives.
[A bell rings.]
I go, and it is done. The bell invites me.
Hear it not, Duncan, for it is a knell
That summons thee to heaven, or to hell.
END

  ALLOWED_LETTERS = (32..122).to_a.map{|i| i.chr}

  class Chromosome
    attr_reader :gene_ary, :target_ary, :gene

    class << self
      def gen_random()
        str=''
        TARGET_GENE.size.times do |i|
          str << ALLOWED_LETTERS[rand(ALLOWED_LETTERS.size)-1]
        end
        Chromosome.new(str)
      end

      def to_int_array(str)
        #convenience method to get an array of strings for any string, compatible with ruby 1.9.3 and 1.8.7
        out=[]
          str.each_byte do |c| out << c end
        out
      end
    end

    def initialize(str='')
      @gene=str == '' ? Chromosome.gen_random.gene : str
      @gene_ary ||= Chromosome.to_int_array(@gene)
      @target_ary ||= Chromosome.to_int_array(TARGET_GENE)
    end

    def fitness
      @fitness ||=
        begin
          #normal -- matches the target string
          diff=0
          gene_ary.size.times do |i| diff += (gene_ary[i].to_i - target_ary[i].to_i).abs  end
          diff
        end
    end

    def mate partner
      #split the chromosome at some random point.
      #create two new chromosomes and return them.
      # chrom1 gets the first half from itself and the second from the partner
      # chrom2 gets the first half from the partner and the second from itself
      pivot = rand( gene_ary.size() - 1)
      ng1= gene[0..pivot] + partner.gene[pivot+1..-1]
      ng2= partner.gene[0..pivot] + gene[pivot+1..-1]
      [ Chromosome.new(ng1) , Chromosome.new(ng2) ]
    end

    def mutate
      newstr=@gene.clone
      newstr[rand(@gene.size)] = ALLOWED_LETTERS[ rand(ALLOWED_LETTERS.size) ]
      Chromosome.new newstr
    end


  end

  class Population
    attr_accessor :population
    Tourney_size = 3

    def each(&block)
      @population.each do |i|
        block.call(i)
      end
    end

    def initialize(size, crossover, elitism, mutation, seed)
      @size = size
      @seed = seed
      srand @seed
      @crossover=crossover
      @elitism=elitism
      @mutation=mutation
      buf = []
      @size.times do |i|
        buf << Chromosome::gen_random()
      end
      # puts @seed.to_s
      @population = buf.sort!{ |a,b| a.fitness <=> b.fitness }
    end

    def tournament_selection
      best = @population[rand(@population.size)]
      Tourney_size.times do |i|
        cont = @population[rand(@population.size)]
        best = cont if cont.fitness < best.fitness
      end
      best
    end

    def evolve
      # inspect
      elitism_mark=(@elitism*@population.size).to_i - 1
      buf = @population[0..elitism_mark]
      sub_pop=@population[elitism_mark+1..-1]
      sub_pop.each_with_index do |chrom, ind|
        if rand <= @crossover
          parent1=tournament_selection
          parent2=tournament_selection
          children = parent1.mate parent2
          children[0] = children[0].mutate if rand < @mutation
          children[1] = children[1].mutate if rand < @mutation
          buf += children
        else
          chrom = chrom.mutate if rand < @mutation
          buf << chrom
        end
        break if buf.size >= @size
      end
      @population = (buf+@population[elitism_mark+1...@size]).sort!{|a,b| a.fitness <=> b.fitness}
      # inspect
    end

    def inspect
      ind ||= -1
      @population[0,5].each do |chrome|
        ind += 1
        puts "[" + ind.to_s + "] "+chrome.gene + ": fitness => " + chrome.fitness.to_s
      end
    end
  end

end




size ||= 2048
crossover ||= 0.8
mutation ||= 0.3
elitism ||= 0.1
seed ||= GAHelloWorld::RAND_SEED

puts "GAHellowWorld Ruby edition by David Heitzman"
puts "target string: #{GAHelloWorld::TARGET_GENE} "
puts "size:#{size} crossover:#{crossover} mutation:#{mutation} elitism:#{elitism} seed:#{seed}"
max_generations = 16384
pop = GAHelloWorld::Population.new(size, crossover, elitism, mutation, seed)
  curgen = 1
  finished=false
  while curgen <= 16384 && !finished
    finished=false
    puts("Generation #{curgen}: #{pop.population[0].gene}. Fitness: #{pop.population[0].fitness}" )
    if pop.population[0].fitness == 0
      puts "Finished-- generation: #{curgen}, gene: #{pop.population.first.gene}. "
      finished=true
    else
      pop.evolve
    end
    curgen += 1
    puts "Reached max generation (#{max_generations}). Current best: #{pop.population.first.gene}" if curgen > max_generations
  end
