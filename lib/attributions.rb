# This defines a collection of AgentsDataObject instances, with some extra functionality rolled in.
class Attributions

  include Enumerable

  # Push in an AgentsDataObject array (usually from a DataObject) as well as the DataType (so we know what order to put things in).
  # TODO - as of now, there is no difference in order based on DataType, so this could be cleaned up.
  def initialize(agents_data_objects)

    raise "nil ADOs passed in to Attributions array" if agents_data_objects.nil?
    agents_data_objects.each do |ado|
      raise "non-ADO (#{ado.class}) passed in to Attributions array" unless ado.class == AgentsDataObject
    end

    # for each of the agent roles in the attribution order, go thru agents_data_objects and 
    # get all of the agents in that role => [ [role1, role1], nil, [role3], [role4], nil ]
    # and sort the groups by view_order
    @attributions = DataType.full_attribution_order.map do |agent_role| 
      agents_data_objects.select {|ado| ado.agent_role_id == agent_role.id }.sort_by {|g| g.view_order }
    end

    # get rid of nils and not grouped
    @attributions.compact!
    @attributions.flatten!
  end
  
  def self.from_agents_hash(data_object, agents_hash)
    agents_data_objects = []
    unless agents_hash.nil?
      agents_hash['agents'].each do |agent_role_label, agents|
        agents.each do |agent|
          agents_data_objects << AgentsDataObject.new(:agent => agent,
                                                      :agent_role_id => agent['agent_role_id'],
                                                      :agent_role => AgentRole.new(
                                                          :label => agent_role_label),
                                                      :view_order => agent['view_order'] )
        end
      end
    end
    attributions = Attributions.new(agents_data_objects)
    attributions.add_license    data_object.license, data_object.rights_statement if data_object.has_attribute?('license') || data_object.has_attribute?('rights_statement')
    attributions.add_supplier   agents_hash['data_supplier'] unless agents_hash.nil? || agents_hash['data_supplier'].nil?
    attributions.add_location   data_object.location if data_object.has_attribute?('location')
    attributions.add_source_url data_object.source_url if data_object.has_attribute?('source_url')
    attributions.add_citation   data_object.bibliographic_citation if data_object.has_attribute?('bibliographic_citation')
    return attributions
  end
  

  # Puts a supplier Agent into the array, after the Author (or first, if no Author)
  def add_supplier(supplier)
    if supplier # If it's nil, don't bother doing anything...
      insert_after_role(AgentsDataObject.new(:agent => supplier,
                                             :agent_role => AgentRole.new(:label => 'Supplier'),
                                             :view_order => 0 ),
                        AgentRole[:Author])
    end
  end

  # Puts a location Agent into the array, at the end
  def add_location(location)
    unless location.blank? # If it's nil, don't bother doing anything...
      @attributions << AgentsDataObject.new(:agent => Agent.just_project_name(location),
                                            :agent_role => AgentRole.new(:label => 'Location'),
                                            :view_order => 0)
    end
  end

  # Puts a Source URL Agent into the array, at the end
  def add_source_url(source_url)                                                  
    unless source_url.blank? # If it's empty, don't bother doing anything...
      @attributions << AgentsDataObject.new(:agent => Agent.from_source_url(source_url),
                                            :agent_role => AgentRole.new(:label => 'Source URL'),
                                            :view_order => 0)
    end
  end

  # Puts a Citation Agent into the array, at the end
  def add_citation(citation)
    unless citation.blank? # If it's nil, don't bother doing anything...
      @attributions << AgentsDataObject.new(:agent => Agent.just_project_name(citation),
                                            :agent_role => AgentRole.new(:label => 'Citation'),
                                            :view_order => 0)
    end
  end

  # now, we need to go in and put the rights statement ... this is very hacky but the 
  # rights statement is supposed to show up after the Source, but it's not actually an attribution
  # so ... we have to stick it into the list somehow for it to show up  :/
  def add_license(license, rights_statement)
    # Nothing to do if there's no license AND no rights_statement
    unless rights_statement.blank? && license.nil?
      license ||= License.public_domain # We assume everything is open unless specified
      insert_after_role(AgentsDataObject.from_license(license, rights_statement),
                        AgentRole[:Author, :Source])
    end
  end

  # Enumerable stuff (note these are untested, as they would cause everything else to fail if they sucked):

  def +(new_attribution)
    if new_attribution.class == AgentsDataObject
      @attributions << new_attribution
    else
      raise "You can only add attributions that are members of the AgentsDataObject class. " << 
            "There are other methods for other objects, see RDocs."
    end
  end

  def each
    @attributions.each { |a| yield a }
  end

  def [](i)
    @attributions[i]
  end

  def first
    @attributions.first
  end

  def last
    @attributions.last
  end

  def <<(ado)
    @attributions << ado
  end

private

  # Take this AgentsDataObject and shove it after the last ADO we find matching the roles specified (or first, if none)
  # Yes, that sounds bizarre.  Why not at the end if there's nothing else matching?  ...Well, those are the specs.  Soooo....
  def insert_after_role(insert_this, role)
    role = [role] unless role.respond_to? :include?
    insert_index = 0
    @attributions.each_with_index do |attr, i|
      insert_index = i + 1 if role.include? attr.agent_role
    end
    @attributions.insert insert_index, insert_this
  end

end
