#
# Step
#
 
module Dopi
  class Step

    attr_reader :name, :nodes, :command


    def initialize(step_config_hash, all_nodes)
      @name = step_config_hash['name']

      # assemble a list of the nodes assigned to the step
      @nodes = []
      unless step_config_hash['nodes'].nil?
        @nodes += get_nodes_from_nodes_list(step_config_hash['nodes'], all_nodes)
      else  
        Dopi.log.debug("No nodes field found for step #{@name}")
      end
      unless step_config_hash['roles'].nil?
        @nodes += get_nodes_from_roles_list(step_config_hash['roles'], all_nodes)
      else
        Dopi.log.debug("No roles field found for step #{@name}")
      end
      @nodes.uniq!
    end


    def get_nodes_from_nodes_list(nodes_list, all_nodes)
      nodes = []
      # Match keywords (corrently there is only "all")
      if nodes_list.class == String
        
        if nodes_list.casecmp('all') == 0
          Dopi.log.debug("Adding all nodes to the step #{@name}")
          nodes = all_nodes
        else
          raise "Unknown keyword #{nodes_list} for nodes field in step #{@name}"
        end
      # Assemble node list from the nodes array
      elsif nodes_list.class == Array
        nodes_list.each do |node_fqdn|
          selected_nodes = all_nodes.select {|n| n.fqdn == node_fqdn}
          raise "node #{node_fqdn} is not defined" if selected_nodes == []
          Dopi.log.debug("Adding node to the step #{@name}")
          Dopi.log.debug(selected_nodes.inspect)
          nodes += selected_nodes
        end
      else
        raise "nodes field in step #{step['name']} is not an array or keyword"
      end
      return nodes
    end


    def get_nodes_from_roles_list(roles_list, all_nodes)
      nodes = []
      if roles_list.class == Array
        roles_list.each do |node_role|
          selected_nodes = all_nodes.select {|n| n.role == node_role}
          Dopi.log.debug("Adding nodes with role #{node_role} to the step #{@name}")
          Dopi.log.debug(selected_nodes.inspect)
          nodes += selected_nodes
        end
      else
        raise "roles field in step #{step['name']} is not an array"
      end
      return nodes
    end


  end
end
