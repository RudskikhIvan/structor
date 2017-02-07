A = 1000.times.map{|i| {name: 'aaa', id: i}}
B = 1000.times.map{|i| {a_id: rand(1000), c_id: rand(1000)}}.uniq
C = 1000.times.map{|i| {name: 'ccc', id: i}}


class TestArray
  def self.var1
    B.map{|b| [b]}.each do |b|
      A.each do |a|
        a[:c] = []
        b << a if b[0][:a_id] == a[:id]
      end
      C.each do |c|
        b << c if b[0][:c_id] == c[:id]
      end
    end.tap{|bs| bs.reject!{|b| b.size < 3}}.each{|b| b.second[:c] << b.last}
    A
  end

  def self.var2
    B.each do |b|
      a = A.find{|_a| _a[:id] == b[:a_id]}
      c = C.find{|_c| _c[:id] == b[:c_id]}
      a[:c] ||= []
      a[:c] << c if c
    end
    A
  end

  def self.var3
    aa = A.each_with_object({}){|_a, st| st[_a[:id]] = _a}
    cc = C.each_with_object({}){|_c, st| st[_c[:id]] = _c}
    B.each do |b|
      a = aa[b[:a_id]]
      c = cc[b[:c_id]]
      a[:c] ||= []
      a[:c] << c if c
    end
    A
  end
end