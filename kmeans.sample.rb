require 'csv'
require 'rubygems'
require 'gnuplot'

INFINITY = 1.0 / 0

class Point
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end
  def dist_to(p)
    xs = (@x - p.x) ** 2
    ys = (@y - p.y) ** 2
    return Math::sqrt(xs + ys)
  end

  def to_s
    return "(#{@x}, #{@y})"
  end
end

class Cluster
  attr_accessor :center, :points

  def initialize(center)
    @center = center
    @points = []
  end

  # 中心位置を再計算し、@centerを更新する.　また、新しい中心と
  # 古い中心との距離を返却する
  def recenter!
    xa = ya = 0
    old_center = @center

    if points.length > 0 then
      @points.each do |point|
        xa += point.x
        ya += point.y
      end
      xa /= @points.length
      ya /= @points.length
      @center = Point.new(xa, ya)
    end
    return old_center.dist_to(center)
  end
end

def kmeans(data, k, delta=0.001)
  clusters = []
  # すべてのクラスタにPointのうち一つを割り付ける
  (1..k).each do |point|
    index = (data.length * rand).to_i
    rand_point = data[index]
    cluster = Cluster.new(rand_point)
    clusters.push cluster
  end

  # Loop
  while true
    data.each do |point|
      min_dist = +INFINITY
      min_cluster = nil

      #全てのクラスタから、一番近いクラスタとその距離を決定する
      clusters.each do |cluster|
        dist = point.dist_to(cluster.center)
        if dist < min_dist
          min_dist = dist
          min_cluster = cluster
        end
      end
      min_cluster.points.push point #一番近いクラスタに所属させる
    end

    #clusterの中心を再計算する
    max_delta = -INFINITY
    clusters.each do |cluster|
      dist_moved = cluster.recenter!

      if dist_moved > max_delta
        max_delta = dist_moved
      end
    end

    #もし全ての中心の移動がdeltaより小さかったらclustersを返却する
    if max_delta < delta
      return clusters
    end

    #clusterに所属するPointを空にする
    clusters.each do |cluster|
      cluster.points = []
    end
  end
end

if __FILE__ == $0
  data = []
  fn = ''
  if ARGV.length == 1
    fn = ARGV[0]
  else
    puts 'Usage: kmeans.rb INPUT-FILE'
    exit
  end

  CSV.foreach(fn) do |row|
    x = row[0].to_f
    y = row[1].to_f

    p = Point.new(x, y)
    data.push p
  end
  puts 'Number of clusters to find:'
  k = STDIN.gets.chomp!.to_i
  clusters = kmeans(data, k)
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
end
