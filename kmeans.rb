require 'rubygems'
require 'gnuplot'

file = open("./petal_data.rb")
petal_data = eval file.read
p petal_data

clusters = kmeans(petal_data, k)

Gnuplot.open do |gp|
  Gnuplot::Plot.new(gp) do |plot|
    plot.title fn
    plot.terminal "png"
    plot.output "./kmeans_result#{`date +'%Y%m%d-%H%M%S'`.chomp!}.png"
    clusters.each do |cluster|
      x = cluster.points.collect{|p| p.x }
      y = cluster.points.collect{|p| p.y }
      plot.data << Gnuplot::DataSet.new([x,y])
      #plot.data << Gnuplot::DataSet.new([x,y]) do |ds|
      #  ds.notitle
      #ds.title = "type1"
      #end
    end
  end
end
