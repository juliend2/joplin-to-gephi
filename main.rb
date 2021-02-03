require 'sqlite3'
require 'sequel'
require 'pp'

DB = Sequel.sqlite("#{ENV['HOME']}/.config/joplin-desktop/database.sqlite")

ds = DB[<<-EOSQL]
  SELECT * FROM notes
EOSQL


def xml(nodes, edges)
  edge_id = -1
	<<-EOXML
	<?xml version="1.0" encoding="UTF-8"?>
	<gexf xmlns="http://www.gexf.net/1.2draft" version="1.2">
			<meta lastmodifieddate="2021-01-26">
					<creator>joplin-to-gephi</creator>
					<description>Joplin export</description>
			</meta>
			<graph mode="static" defaultedgetype="directed">
					<nodes>
							#{nodes.map{|node|
                "<node id='#{node[:id]}' label='#{node[:title].gsub("'", "’").gsub("&", "&amp;")}' />"
              }.join("\n")}
					</nodes>
					<edges>
              #{edges.map{|edge|
                edge_id += 1
                "<edge id='#{edge_id}' source='#{edge[:from]}' target='#{edge[:to]}' />"
              }.join("\n")}
					</edges>
			</graph>
	</gexf>
	EOXML
end

edges = []
nodes_map = {}
ds.each do |note|
  nodes_map[ note[:id] ] = { title: note[:title] , related: []}
  # Example link:
  # [Cue](:/fe08a3d7a921421fbb73de71a19c5531)
  matches = note[:body].scan(/\]\(:\/(\h{32})\)/)
  related = []

  # Build something like:
  #
  # "09508b4f93cf4804b1e4d085da74297a"=>
  #  {:title=>"Les Hommes",
  #   :related=>
  #    ["ec812c6a20454638bcd467eb80c701dc", "8d10f19dd29b41238ee7ea26ebbf5a08"]},
  if matches.length > 0
    related = matches.map{|m| m.first }.uniq
    nodes_map[ note[:id] ][:related] = related
  end
end

nodes = nodes_map.map{|k, v| {id: k, title: v[:title]} }
edges = nodes_map.map{|k, v| v[:related].map{|related| {from: k, to: related} } }.flatten
#pp edges
puts xml(nodes, edges)
