Factory.sequence(:grumbler_name) do |n|
  "Joe Example the #{n.ordinalize}"
end

Factory.define(:target) do |target|
  target.sequence(:uri) {|n| "http://www.example.com/posts/#{n}" }
  target.grumbles do |g|
    [g.association(:grumble), g.association(:grumble, :grumbler => nil)]
  end
end

Factory.define(:grumble) do |grumble|
  grumble.subject "Roads"
  grumble.body "Hi"
  grumble.association :grumbler
  grumble.anon_grumbler_name do |g|
    g.grumbler ? nil : Factory.next(:grumbler_name)
  end
end

Factory.define(:grumbler) do |grumbler|
  grumbler.name { Factory.next(:grumbler_name) }
end
