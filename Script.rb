#===============================================================================
# * Triple Triad Booster Pack - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It's a booster pack item for 
# Triple Triad minigame.
#
#===============================================================================
#
# To this script works, put it above main. Put an item into item.txt like:
#
# 712,BOOSTERPACK,Booster Pack,1,500,An booster pack for Triple Triad game. Contains 3 cards ,2,0,0,
#
# You can set a max/min value for the biggest attribute in a card. So, you can
# create several types of packs, an example where 3 is the number of cards,
# 5 is the minimum level and 9 is the maximum level:
#
# ItemHandlers::UseFromBag.add(:SUPERPACK,proc{|item|
#   giveBoosterPack(item,3,5,9)
# })
#
# This script generates random cards, but generate some cards in order to a
# player won't reset the game trying to get other cards. The variable
# MIN_BOOSTER_STOCK defines how many cards are stocked in save. If the number
# in this variable is 5, by example, and the values are initialized. Even if
# the player saves and keep opening the packs and resetting, he gets the same
# first 5 cards, since these cards are randomized only the 5 cards ahead. To
# disable this feature, just make the variable value as 0.
#
# I suggest you to initialize this list after the professor lecture, for all 
# packs. If, in your game, you have packs from min/max levels from 2/4, 3/6
# and 5/9, after professor lecture add the script commands:
#
# $PokemonGlobal.fillBoosterStock(2,4)
# $PokemonGlobal.fillBoosterStock(3,6)
# $PokemonGlobal.fillBoosterStock(5,9)
#
#===============================================================================

MIN_BOOSTER_STOCK=30

if MIN_BOOSTER_STOCK>0
  class PokemonGlobalMetadata
    def fillBoosterStock(minLevel,maxLevel)
      @boosterStock=[]  if !@boosterStock
      @boosterStock[minLevel]=[] if @boosterStock.size<=minLevel
      if @boosterStock[minLevel].size<=maxLevel
        @boosterStock[minLevel][maxLevel]=[]
      end
      while @boosterStock[minLevel][maxLevel].size<MIN_BOOSTER_STOCK
        randomCard = getRandomTriadCard(minLevel,maxLevel)
        @boosterStock[minLevel][maxLevel].push(randomCard)
      end
    end
    
    def getFirstBoosterAtStock(minLevel,maxLevel)
      # Called twice since the variable maybe isn't initialized
      fillBoosterStock(minLevel,maxLevel)
      newCard = @boosterStock[minLevel][maxLevel].shift
      fillBoosterStock(minLevel,maxLevel)
      return newCard
    end
  end
end  

def getRandomTriadCard(minLevel,maxLevel)
  overflowCount=0
  loop do
    overflowCount+=1
    raise "Can't draw a random card!" if overflowCount>10000
    randomPokemon = rand(PBSpecies.maxValue)+1
    cname=getConstantName(PBSpecies,randomPokemon) rescue nil
    next if !cname
    triad=TriadCard.new(randomPokemon)
    level=[triad.north,triad.south,triad.east,triad.west].max
    next if level<minLevel || level>maxLevel
    return randomPokemon
  end 
end  

def giveBoosterPack(item,numberOfCards,minLevel=0,maxLevel=20)
  Kernel.pbMessage(_INTL("{1} opened the {2}.",
      $Trainer.name,PBItems.getName(item)))
  cardEarned = 0
  overflowCount = 0
  for i in 0...numberOfCards
    card=-1
    if MIN_BOOSTER_STOCK>0
      card = $PokemonGlobal.getFirstBoosterAtStock(minLevel,maxLevel)
    else
      card = getRandomTriadCard(minLevel,maxLevel)
    end
    pbGiveTriadCard(card,1)
    Kernel.pbMessage(_INTL("{1} draws {2} card!",
        $Trainer.name,getConstantName(PBSpecies,card)))
  end
  return 3
end

ItemHandlers::UseFromBag.add(:BOOSTERPACK,proc{|item|
  giveBoosterPack(item,3)
})