# An enumerated list of the different kinds of roles an Agent fills.
class AgentRole < SpeciesSchemaModel

  acts_as_enum

  has_many :agents_data_objects
  has_many :agents_synonyms
  
  # Find the "Source" AgentRole.
  def self.source_id
    Rails.cache.fetch('agent_roles/source_id') do
      AgentRole.find_by_label('Source').id
    end
  end
  
  # Find the "contributor" AgentRole.
  def self.contributor_id
    Rails.cache.fetch('agent_roles/contributor_id') do
      AgentRole.find_by_label('Contributor').id
    end
  end
  
  # Find the "Author" AgentRole.
  def self.author_id
    Rails.cache.fetch('agent_roles/author_id') do
      AgentRole.find_by_label('Author').id
    end
  end
  
  # Find the "Photographer" AgentRole.
  def self.photographer_id
    Rails.cache.fetch('agent_roles/photographer_id') do
      AgentRole.find_by_label('Photographer').id
    end
  end
    
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_roles
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null
