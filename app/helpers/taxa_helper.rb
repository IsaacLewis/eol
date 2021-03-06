module TaxaHelper

  # These start out display:none, so we can show them only after JS behaviours have been applied.
  # which: a string to be used to create the ID of the anchor: try 'comment', 'tagging', or 'curator'.
  # where: the URL you want the anchor to reference (used by JS to create an Ajax request).
  def popup_link(which, where, options = {})
    html_options = {
      :id => "large-image-#{which}-button-popup-link", :class => 'popup-link', :style => 'display:none;'
    }.merge(options)
    link_to '<span style="display:block;width:24px;height:25px;"></span>', where, html_options
  end

  def vetted_id_class(data_object)
    return case data_object.vetted_id
      when Vetted.unknown.id   then 'unknown-background-image'
      when Vetted.untrusted.id then 'untrusted-background-image'
      when Vetted.trusted.id   then 'trusted-background-image'
      else nil
    end
  end
    
  def agent_partial(original_agents, params={})
    return '' if original_agents.nil? or original_agents.blank?
    params[:linked] = true if params[:linked].nil?
    params[:only_first] ||= false
    params[:show_link_icon] = true if params[:show_link_icon].nil?
    agents = original_agents.clone # so we can be destructive.
    agents = [agents] unless agents.class == Array # Allows us to pass in a single agent, if needed.
    agents = [agents[0]] if params[:only_first]
    agent_list = agents.collect do |agent|
      params[:linked] ? external_link_to(allow_some_html(agent.full_name),
                                         agent.homepage,
                                         {:show_link_icon => params[:show_link_icon]}) :
                        allow_some_html(agent.full_name)
    end
    agent_list = agent_list.join(', ')
    agent_list += ', et al.' if params[:only_first] and original_agents.length > 1
    return agent_list
  end

  def agent_icons_partial(original_agents,params={})
    return '' if original_agents.nil? or original_agents.blank?
    params[:linked] = true if params[:linked].nil?
    params[:show_text_if_no_icon] ||= false
    params[:only_show_col_icon] ||= false
    params[:normal_icon] ||= false
    params[:separator] ||= "&nbsp;"
    params[:last_separator] ||= params[:separator]
    params[:taxon] ||= false
    
    is_default_col = false
    if(params[:taxon] != false && !params[:taxon].col_entry.nil?)
      is_default_col = true
    end
    
    agents = original_agents.clone # so we can be destructive.
    agents = [agents] unless agents.class == Array # Allows us to pass in a single agent, if needed.
    
    output_html = []
    
    agents.each do |agent|
      logo_size = (agent == Agent.catalogue_of_life ? "large" : "small") # CoL gets their logo big     
      if agent.logo_cache_url.blank? 
        output_html << agent_partial(agent,params) if params[:show_text_if_no_icon] 
      else
        url = agent.homepage.strip || ''
        
        # if the agent is Catalogue of Life then look for a mapping and link the logo to their site
        if agent == Agent.catalogue_of_life && params[:taxon]
          if collection = Collection.find_by_agent_id(agent.id, :limit => 1, :order => 'id desc')
            mappings = collection.find_mappings_by_taxon_concept(params[:taxon])
            url = mappings[0].url if !mappings.empty?
          end
        end
        
        if params[:only_show_col_icon] && !is_default_col # if we are only asked to show the logo if it's COL and the current agent is *not* COL, then show text
          output_html << agent_partial(agent,params)
        else
          if params[:linked] and not url.blank?
            text = agent_logo(agent,logo_size,params)
            output_html << external_link_to(text,url,{:show_link_icon => false})
          else
            output_html << agent_logo(agent,logo_size,params)
          end
        end
      end
      
    end
    
    if output_html.size > 1 && params[:last_separator] != params[:separator]
      # stich the last two elements together with the "last separator" column before joining if there is more than 1 element and the last separator is different
      output_html[output_html.size-2] += params[:last_separator] + output_html.pop
		end

    return output_html.compact.join(params[:separator]) 

  end
    
  def we_have_css_for_kingdom?(kingdom)
    return false if kingdom.nil?
    return $KINGDOM_IDs.include?(kingdom.id.to_s)
  end
  
  def show_next_image_page_button
    if params[:image_page].blank?
      show_next_image_page_button = @taxon_concept.more_images 
    else
      image_page = (params[:image_page] ||= 1).to_i
      start       = $MAX_IMAGES_PER_PAGE * (image_page - 1)
      last        = start + $MAX_IMAGES_PER_PAGE - 1
      show_next_image_page_button = (@taxon_concept.images.length > (last + 1))
    end
  end

  def video_hash(video,taxon_concept_id='')
    # TODO: (something of a big change, since it means altering the JS)
    #       Note that this won't handle the agent_partial stuff; handle separately:
    # return video.to_json(:methods => :video_url)
    if taxon_concept_id.blank? # grab the first taxon concept ID from the video object if we didn't just pass it in
      taxon_concepts=video.taxa_names_taxon_concept_ids
      taxon_concept_id = taxon_concepts[0][:taxon_concept_id] unless taxon_concepts.blank?
    end
    data_supplier = video.data_supplier_agent
    data_supplier_name = data_supplier ? data_supplier.full_name : ''
    data_supplier_url = data_supplier ? data_supplier.homepage : ''
    data_supplier_icon = data_supplier ? agent_icons_partial(data_supplier) : ''
    
    return "{author: '"         + escape_javascript(agent_partial(video.authors)) +
           "', nameString: '"   + escape_javascript(video.taxa_names_ids[0]['taxon_name']) +
           "', collection: '"   + escape_javascript(agent_partial(video.sources)) +
           "', location: '"     + escape_javascript(video.location || '') +
           "', info_url: '"     + escape_javascript(video.source_url || '') +
           "', field_notes: '"  + escape_javascript(video.description || '') +
           "', license_text: '" + escape_javascript(video.license_text || '') +
           "', license_logo: '" + escape_javascript(video.license_logo || '') +
           "', license_link: '" + escape_javascript(video.license_url || '') +
           "', title:'"         + escape_javascript(video.object_title) +
           "', video_type:'"    + escape_javascript(video.media_type) +
           "', video_trusted:'" + escape_javascript(video.vetted_id.to_s) +
           "', video_data_supplier:'" + escape_javascript(data_supplier.to_s) +
           "', video_supplier_name:'" + escape_javascript(data_supplier_name.to_s) +
           "', video_supplier_url:'"  + escape_javascript(data_supplier_url.to_s) +
           "', video_supplier_icon:'" + escape_javascript(data_supplier_icon.to_s) +
           "', video_url:'"     + escape_javascript("#{video.video_url}" || video.object_url || '') +
           "', data_object_id:'"+ escape_javascript(video.id.to_s) +
           "', taxon_concept_id:'#{taxon_concept_id}'}"
  end
  
  def paginate_results(search)
    pages = search.total_pages
    current_page = search.current_page
    html  = Builder::XmlMarkup.new
    html.div(:class => 'serp_pagination') do

      html << deactivatable_link('&lt;&lt;&nbsp;Prev',
                                 :href => search_by_page_href(current_page - 1),
                                 :deactivated => current_page == 1)
      
      lower_bound = current_page - 10
      lower_bound = 1 if lower_bound < 1
      upper_bound = current_page + 10
      upper_bound = pages if upper_bound > pages

      (lower_bound..upper_bound).each do |page|
        html.span(:class => 'pg_link') {
          html << deactivatable_link(page.to_s,
                                     :href => search_by_page_href(page),
                                     :deactivated => current_page == page)
        }
      end
      
      html << deactivatable_link('Next&nbsp;&gt;&gt;',
                                 :href => search_by_page_href(current_page + 1),
                                 :deactivated => current_page == pages)
    end
  end
  
  def reformat_specialist_projects(projects)
    max_columns = 2
    num_mappings = projects.size
    num_columns = num_mappings < max_columns ? num_mappings : max_columns
    res = []
    until projects.empty? do
      res << projects.shift(num_columns)
    end
    (num_columns - res[-1].size).times do
      res[-1] << nil
    end
    [res, num_columns]
  end

  def specialist_project_collection_link(collection)
    links = []
    collection.collection_types.each do |collection_type|
      links << collection_type.materialized_path_labels
    end
    links.empty? ? collection.title : links.join(', ')
  end

  def common_names_by_language(names, preferred_language_id)
    names_by_language = {}
    # Get some languages we'll need
    eng     = Language.english
    pref    = Language.find(preferred_language_id)
    unknown = Language.unknown
    # Build a hash with language label as key and an array of CommonNameDispaly objects as values
    names.each do |name|
      language = {:id => name.language_id, :label => name.language_label, :name => name.language_name}
      k = name.language_label
      k = unknown.label if k.blank?
      names_by_language.key?(k) ? names_by_language[k] << name : names_by_language[k] = [name]
    end
    remove_duplicate_names(names_by_language)    
    results = []
    # Put preferred first
    results << [pref.label, names_by_language.delete(pref.label)] if names_by_language.key?(pref.label)
    # Sort the rest by language label
    names_by_language.to_a.sort_by {|a| a[0].to_s}.each {|a| results << a}
    # Move unknown to the end
    unknown_data = names_by_language.key?(unknown.label) ? [unknown.label, names_by_language.delete(unknown.label)] : nil
    results << unknown_data if unknown_data
    results
  end

# A *little* weird to have private methods in the helper, but these really help clean up the code for the methods
# that are public, and, indeed, should never be called outside of this class.
private
  
  def search_by_page_href(link_page)
    lparams = params.clone
    lparams["page"] = link_page
    lparams.delete("action")
    "/search/?#{lparams.to_query}"
  end
  
  def deactivatable_link(text, options)
    deactivated = options.delete(:deactivated)
    raise "Cannot create deactivatable link without href option" unless options.has_key? :href
    raise "Cannot create deactivatable link without deactivated option" if deactivated.nil?
    html = Builder::XmlMarkup.new
    if deactivated
      html << text
    else
      html.a(options) { html << text } # Block style, so that the text is handled 'raw', rather than interpolated
    end
    html << '&nbsp;'
    return html.to_s # TODO - without the to_s, this injects some weird markup (<respond_to?:to_str>true</..etc>)
                     # With this to_s, that problem is solved, but this STILL injects <to_s/>  ... WTF?
  end

  def show_next_image_page_button
    if params[:image_page].blank?
      show_next_image_page_button = @taxon_concept.more_images 
    else
      image_page = (params[:image_page] ||= 1).to_i
      start       = $MAX_IMAGES_PER_PAGE * (image_page - 1)
      last        = start + $MAX_IMAGES_PER_PAGE - 1
      show_next_image_page_button = (@taxon_concept.images.length > (last + 1))
    end
  end

  def remove_duplicate_names(names)
    names.each do |lang, names_in_language|
      names_in_language.each_with_index do |name_a, index_a|
        names_in_language.each_with_index do |name_b, index_b|
          next if index_a == index_b
          if name_a.id == name_b.id
            name_a.duplicate = true
            name_b.duplicate = true
            name_a.duplicate_with_curator = true if name_b.in_curator_hierarchy?
            name_b.duplicate_with_curator = true if name_a.in_curator_hierarchy?
          end
        end
      end
      # Remove entries that are duplicates in the curator hierarchy
      names_in_language.delete_if {|name| name.duplicate_with_curator }
    end
  end

end
