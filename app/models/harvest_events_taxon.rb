class HarvestEventsTaxon < SpeciesSchemaModel
  belongs_to :harvest_event
  belongs_to :taxon
  belongs_to :status
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: harvest_events_taxa
#
#  harvest_event_id :integer(4)      not null
#  status_id        :integer(1)      not null
#  taxon_id         :integer(4)      not null
#  guid             :string(32)      not null

