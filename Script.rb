#===============================================================================
# * Triple Triad Booster Pack - by FL (Credits will be appreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It's a booster pack item with
# predefined sets for Triple Triad minigame.
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above main OR convert into a plugin. Add into
# PBS\items.txt:
#
# In Essentials version 20 or above:
#
#  [BOOSTERPACK]
#  Name = Booster Pack
#  NamePlural = Booster Packs
#  Pocket = 1
#  Price = 1000
#  FieldUse = Direct
#  Flags = Fling_30
#  Description = A booster pack for Triple Triad game. Contains 5 cards.
#  [STARTERPACK]
#  Name = Starter Pack
#  NamePlural = Starter Packs
#  Pocket = 1
#  Price = 500
#  FieldUse = Direct
#  Flags = Fling_30
#  Description = A booster pack for Triple Triad game. Contains 3 starter cards.
#
# In v16-v19.1:
#
#  712,BOOSTERPACK,Booster Pack,Booster Packs,1,1000,"A booster pack for Triple Triad game. Contains 5 cards.",2,0,0,
#  713,STARTERPACK,Starter Pack,Starter Packs,1,500,"A booster pack for Triple Triad game. Contains 3 starter cards.",2,0,0,
#
# In v15.2 or below:
#
#  712,BOOSTERPACK,Booster Pack,1,1000,"A booster pack for Triple Triad game. Contains 5 cards.",2,0,0,
#  713,STARTERPACK,Starter Pack,1,500,"A booster pack for Triple Triad game. Contains 3 starter cards.",2,0,0,
#
#== HOW TO USE =================================================================
#
# You can set the booster pack list on LIST. So, you can create several types of 
# packs.
#
#== NOTES ======================================================================
#
# This script generates random cards, but pre-generates some cards forward at
# player save. So player can't reset the game trying to get other cards. I 
# suggest you to initialize this list after the professor lecture, for all
# packs. Just call 'BoosterPack.initialize_all_packs' at end of lecture event.
#
# The variable MIN_PACK_STOCK defines how many cards are pre-generated in save.
# If the number in this variable is 5, by example, and the values are
# initialized. Even if the player saves and keep opening the packs and
# resetting, he gets the same first 5 cards, since these cards are randomized
# ahead. To disable this feature, just make the variable value as 0.
#
# For helping in making booster pack lists, this script includes the method
# 'BoosterPack.print_species_array(type)' that prints all the IDs of a pokémon
# type. An example: if you call the code: 
# 'BoosterPack.print_species_array(:DRAGON)', the species ID array of all Dragon
# pokémon in pokemon.txt will be printed into a window (if you use Essentials
# version 19 or newer, it is also copied into your cilpboard/Ctrl+V). If you
# paste it into the list index 3 (remember that the first index is 0), all that
# you need to do in the item script is:
#
# ItemHandlers::UseFromBag.add(:DRAGONPACK,proc{|item|
#   BoosterPack.give(item,3,3)
#   next 1
# })
#
#===============================================================================

if defined?(PluginManager) && !PluginManager.installed?("Triple Triad Booster Pack")
  PluginManager.register({                                                 
    :name    => "Triple Triad Booster Pack",                                        
    :version => "1.1.1",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?t=356231",             
    :credits => "FL"
  })
end

module BoosterPack  
  LIST=[
    # The below line is the booster of index 0 or full random
    nil,
    # The below lines are the booster of index 1: Starter Pack
    [
      :BULBASAUR, :CHARMANDER, :SQUIRTLE, :CHIKORITA, :CYNDAQUIL, :TOTODILE,
      :TREECKO, :TORCHIC, :MUDKIP, :TURTWIG, :CHIMCHAR, :PIPLUP, 
      :SNIVY, :TEPIG, :OSHAWOTT
    ],
    # The below lines are the booster of index 2: Kanto Normal Pack
    [
      :PIDGEY, :PIDGEOTTO, :PIDGEOT, :RATTATA, :RATICATE, :SPEAROW, :FEAROW, 
      :JIGGLYPUFF, :WIGGLYTUFF, :MEOWTH, :PERSIAN, :FARFETCHD, :DODUO, :DODRIO,
      :LICKITUNG, :CHANSEY, :KANGASKHAN, :TAUROS, :DITTO, :EEVEE, :PORYGON,
      :SNORLAX
    ]
  ]

  MIN_PACK_STOCK=30

  module_function

  def initialize_all_packs
    for i in 0...BoosterPack::LIST.size
      $PokemonGlobal.fill_booster_stock(i)
    end
  end

  def validate_list
    for pack_list in LIST
      next if !pack_list || pack_list.empty?
      raise ArgumentError.new(
        "#{get_invalid_species_sym(pack_list)} isn't a valid species!"
      ) if get_invalid_species_sym(pack_list)
    end
  end

  def get_invalid_species_sym(array)
    return array.find{|s| !Bridge.species_sym_is_valid(s) }
  end

  def random_card(booster_list)
    if !booster_list || booster_list.empty?
      return Bridge.random_species
    end
    return booster_list[rand(booster_list.size)]
  end

  def random_card_by_index(index)
    return random_card(LIST[index])
  end    
  
  def give(item,numberOfCards,booster_index=0)
    validate_list
    Bridge.message(_INTL(
      "{1} opened the {2}.", Bridge.player.name, Bridge.item_name(item)
    ))
    numberOfCards.times do
      if MIN_PACK_STOCK>0
        card_species = $PokemonGlobal.first_booster_at_stock(booster_index)
      else
        card_species = random_card_by_index(booster_index)
      end
      Bridge.give_triad_card(card_species,1)
      Bridge.message(_INTL(
        "{1} draws {2} card!",
        Bridge.player.name,
        Bridge.species_name(card_species))
      )
    end
    return Bridge.end_item_as_consumed_code
  end
  
  def print_species_array(type)
    Bridge.print_value(create_species_array(type))
  end  
  
  def create_species_array(type)
    return Bridge.create_species_array(type)
  end  

  # Essentials multiversion layer
  module Bridge
    if defined?(Essentials)
      MAJOR_VERSION = Essentials::VERSION.split(".")[0].to_i
    else
      MAJOR_VERSION = 0
    end

    module_function

    def message(string)
      return MAJOR_VERSION >= 19 ? pbMessage(string) : Kernel.pbMessage(string)
    end

    def end_item_as_consumed_code
      return MAJOR_VERSION >= 20 ? 1 : 3
    end

    def give_triad_card(sym, quantity)
      pbGiveTriadCard(
        (MAJOR_VERSION >= 19 ? sym : getID(PBSpecies, sym)), quantity
      )
    end 

    def player
      return MAJOR_VERSION >= 20 ? $player : $Trainer
    end 

    def species_name(species)
      return PBSpecies.getName(getID(PBSpecies, species)) if MAJOR_VERSION < 19
      return GameData::Species.get(species).name
    end

    def species_sym_is_valid(species_sym)
      return getConst(PBSpecies, species_sym) != nil if MAJOR_VERSION < 19
      return GameData::Species.try_get(species_sym) != nil 
    end

    def random_species
      if MAJOR_VERSION < 19
        return getConstantName(PBSpecies, rand(PBSpecies.maxValue)+1).to_sym
      end
      random_species_array = create_random_species_array_v19_plus
      return random_species_array[rand(random_species_array.size)]
    end    
    
    def create_random_species_array_v19_plus
      ret =[]
      GameData::Species.each_species{ |species| ret.push(species.id)}
      return ret
    end
    
    def print_value(value)
      Input.clipboard = value.to_s if MAJOR_VERSION >= 19
      print(value.inspect)
    end
    
    def create_species_array(type)
      ret = []
      if MAJOR_VERSION >= 19
        GameData::Species.each_species { |species|
          if MAJOR_VERSION == 19
            ret.push(species.id) if species.type1==type || species.type2==type
          else
            ret.push(species.id) if species.types.include?(type)
          end
        }
      else
        dexdata=pbOpenDexData
        for species in 1..PBSpecies.maxValue
          pbDexDataOffset(dexdata,species,8)
          type1=dexdata.fgetb
          type2=dexdata.fgetb
          if isConst?(type1,PBTypes,type) || isConst?(type2,PBTypes,type)
            ret.push(getConstantName(PBSpecies, species).to_sym) 
          end
        end
      end
      return ret
    end

    def item_name(item)
      return PBItems.getName(getID(PBItems, item)) if MAJOR_VERSION < 19
      return GameData::Item.get(item).name
    end
  end
end


if BoosterPack::MIN_PACK_STOCK>0
  class PokemonGlobalMetadata
    def fill_booster_stock(booster_index)
      @booster_stock=[]  if !@booster_stock
      if @booster_stock.size<=booster_index || !@booster_stock[booster_index]
        @booster_stock[booster_index]=[]
      end
      while @booster_stock[booster_index].size < BoosterPack::MIN_PACK_STOCK
        @booster_stock[booster_index].push(
          BoosterPack.random_card_by_index(booster_index)
        )
      end
    end
    
    # Gives the first available booster at stock.
    # Call fill_booster_stock before and after since the variable on first time
    # isn't initialized
    def first_booster_at_stock(booster_index)
      fill_booster_stock(booster_index)
      ret = @booster_stock[booster_index].shift
      fill_booster_stock(booster_index)
      return ret
    end
  end
end

ItemHandlers::UseFromBag.add(:BOOSTERPACK,proc{|item|
  next BoosterPack.give(item, 5)
})
ItemHandlers::UseFromBag.add(:STARTERPACK,proc{|item|
  next BoosterPack.give(item, 3, 1)
})