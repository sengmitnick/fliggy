# frozen_string_literal: true

# 深度旅行讲解员评价数据包
# 为各个讲解员提供真实的用户评价
#
# 用途：
# - 提供讲解员的真实评价展示
# - 帮助用户了解讲解员的服务质量
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载深度旅行评价数据包..."

# 获取讲解员和用户
guides = DeepTravelGuide.where(
  name: ["叶强", "李明华", "惟真", "陈海派", "李楚天", "吴园林"]
).index_by(&:name)

default_user_id = User.first&.id || 1

all_reviews = []

# 叶强的评价（故宫博物院 - 评分4.9）
if guides["叶强"]
  叶强_reviews = [
    {
      deep_travel_guide_id: guides["叶强"].id,
      user_id: default_user_id,
      rating: 5.0,
      content: "叶导游专业知识非常扎实，讲解生动有趣，把故宫的历史文化讲得很透彻。带我们走了很多游客不知道的小路，避开了人流，体验非常好！强烈推荐！",
      helpful_count: 156,
      visit_date: Date.today - 15.days,
      data_version: '0',
      created_at: Time.current - 15.days,
      updated_at: Time.current - 15.days
    },
    {
      deep_travel_guide_id: guides["叶强"].id,
      user_id: default_user_id,
      rating: 4.9,
      content: "第一次来故宫就选对了导游！叶老师对故宫的每一个细节都了如指掌，讲解的时候还会结合历史故事，让我对明清历史有了全新的认识。就是人有点多，建议早点去。",
      helpful_count: 89,
      visit_date: Date.today - 22.days,
      data_version: '0',
      created_at: Time.current - 22.days,
      updated_at: Time.current - 22.days
    },
    {
      deep_travel_guide_id: guides["叶强"].id,
      user_id: default_user_id,
      rating: 4.8,
      content: "很专业的讲解员，带着父母和孩子一起去的，叶导游照顾到了每个人的节奏，讲解内容深入浅出，老人孩子都听得很开心。性价比很高！",
      helpful_count: 73,
      visit_date: Date.today - 8.days,
      data_version: '0',
      created_at: Time.current - 8.days,
      updated_at: Time.current - 8.days
    },
    {
      deep_travel_guide_id: guides["叶强"].id,
      user_id: default_user_id,
      rating: 5.0,
      content: "非常满意的一次体验！叶导游不仅讲解专业，还很会拍照，帮我们拍了很多好看的照片。6个小时的行程一点都不累，每个宫殿都有故事。下次来北京还找他！",
      helpful_count: 134,
      visit_date: Date.today - 30.days,
      data_version: '0',
      created_at: Time.current - 30.days,
      updated_at: Time.current - 30.days
    },
    {
      deep_travel_guide_id: guides["叶强"].id,
      user_id: default_user_id,
      rating: 4.9,
      content: "作为历史爱好者，这次故宫之行收获满满。叶老师对建筑、文物、历史都有深入研究，回答问题也很耐心。唯一遗憾是时间太短了，下次要预约全天的。",
      helpful_count: 67,
      visit_date: Date.today - 5.days,
      data_version: '0',
      created_at: Time.current - 5.days,
      updated_at: Time.current - 5.days
    }
  ]
  all_reviews.concat(叶强_reviews)
end

# 李明华的评价（故宫博物院 - 评分4.9）
if guides["李明华"]
  李明华_reviews = [
    {
      deep_travel_guide_id: guides["李明华"].id,
      user_id: default_user_id,
      rating: 5.0,
      content: "李老师讲的后宫秘史太精彩了！把我们平时在电视剧里看到的情节都还原了真实的历史，很多细节都是第一次听说。两个小时根本不够，意犹未尽！",
      helpful_count: 145,
      visit_date: Date.today - 12.days,
      data_version: '0',
      created_at: Time.current - 12.days,
      updated_at: Time.current - 12.days
    },
    {
      deep_travel_guide_id: guides["李明华"].id,
      user_id: default_user_id,
      rating: 4.8,
      content: "20年的研究功底不是盖的，李导游对故宫的了解太深了。讲解风格也很生动，不会让人觉得枯燥。就是走得有点快，年纪大的游客可能会累。",
      helpful_count: 58,
      visit_date: Date.today - 18.days,
      data_version: '0',
      created_at: Time.current - 18.days,
      updated_at: Time.current - 18.days
    },
    {
      deep_travel_guide_id: guides["李明华"].id,
      user_id: default_user_id,
      rating: 5.0,
      content: "非常值得！李老师把皇帝的私生活和后宫的故事讲得特别有意思，感觉自己穿越回了清朝。珍宝馆的讲解也很专业，这个价格真的很超值。",
      helpful_count: 92,
      visit_date: Date.today - 7.days,
      data_version: '0',
      created_at: Time.current - 7.days,
      updated_at: Time.current - 7.days
    }
  ]
  all_reviews.concat(李明华_reviews)
end

# 惟真的评价（秦始皇帝陵博物院 - 评分4.9）
if guides["惟真"]
  惟真_reviews = [
    {
      deep_travel_guide_id: guides["惟真"].id,
      user_id: default_user_id,
      rating: 4.9,
      content: "惟真老师讲解非常专业，对兵马俑的历史、制作工艺都讲得很详细。还带我们看了很多细节，比如不同兵种的区别。两个小时的讲解物超所值！",
      helpful_count: 112,
      visit_date: Date.today - 10.days,
      data_version: '0',
      created_at: Time.current - 10.days,
      updated_at: Time.current - 10.days
    },
    {
      deep_travel_guide_id: guides["惟真"].id,
      user_id: default_user_id,
      rating: 5.0,
      content: "金牌导游果然名不虚传！惟真老师不仅讲解专业，还很会照顾游客。带着孩子来的，她用孩子能听懂的方式讲秦朝历史，孩子听得津津有味。超级推荐！",
      helpful_count: 87,
      visit_date: Date.today - 20.days,
      data_version: '0',
      created_at: Time.current - 20.days,
      updated_at: Time.current - 20.days
    },
    {
      deep_travel_guide_id: guides["惟真"].id,
      user_id: default_user_id,
      rating: 4.8,
      content: "很满意的一次讲解服务。惟真老师对三个坑的兵马俑都有深入研究，讲解内容丰富且有条理。美中不足的是游客太多了，有时候听不太清楚。",
      helpful_count: 43,
      visit_date: Date.today - 4.days,
      data_version: '0',
      created_at: Time.current - 4.days,
      updated_at: Time.current - 4.days
    }
  ]
  all_reviews.concat(惟真_reviews)
end

# 陈海派的评价（上海外滩 - 评分4.9）
if guides["陈海派"]
  陈海派_reviews = [
    {
      deep_travel_guide_id: guides["陈海派"].id,
      user_id: default_user_id,
      rating: 5.0,
      content: "陈导游讲的十里洋场故事太精彩了！每栋建筑背后的历史都娓娓道来，感觉上海滩的繁华岁月就在眼前。特级导游果然不一样，强烈推荐！",
      helpful_count: 98,
      visit_date: Date.today - 14.days,
      data_version: '0',
      created_at: Time.current - 14.days,
      updated_at: Time.current - 14.days
    },
    {
      deep_travel_guide_id: guides["陈海派"].id,
      user_id: default_user_id,
      rating: 4.9,
      content: "很专业的讲解，陈老师对外滩建筑群如数家珍，讲解风格也很有魅力。晚上看夜景特别美，这个价格物有所值。",
      helpful_count: 65,
      visit_date: Date.today - 6.days,
      data_version: '0',
      created_at: Time.current - 6.days,
      updated_at: Time.current - 6.days
    }
  ]
  all_reviews.concat(陈海派_reviews)
end

# 李楚天的评价（武汉黄鹤楼 - 评分4.8）
if guides["李楚天"]
  李楚天_reviews = [
    {
      deep_travel_guide_id: guides["李楚天"].id,
      user_id: default_user_id,
      rating: 4.8,
      content: "李导游对黄鹤楼的历代诗词讲解得很透彻，每首诗背后的历史故事都很有意思。三国文化和楚文化结合得很好，收获很大！",
      helpful_count: 76,
      visit_date: Date.today - 9.days,
      data_version: '0',
      created_at: Time.current - 9.days,
      updated_at: Time.current - 9.days
    },
    {
      deep_travel_guide_id: guides["李楚天"].id,
      user_id: default_user_id,
      rating: 4.9,
      content: "非常满意的一次体验！李老师讲解专业又生动，还带我们去了长江大桥，视野很开阔。武汉的历史文化底蕴原来这么深厚。",
      helpful_count: 54,
      visit_date: Date.today - 16.days,
      data_version: '0',
      created_at: Time.current - 16.days,
      updated_at: Time.current - 16.days
    }
  ]
  all_reviews.concat(李楚天_reviews)
end

# 吴园林的评价（苏州园林 - 评分4.9）
if guides["吴园林"]
  吴园林_reviews = [
    {
      deep_travel_guide_id: guides["吴园林"].id,
      user_id: default_user_id,
      rating: 5.0,
      content: "吴老师是真正的园林专家！从造园手法到文化内涵都讲得非常深入，让我对江南园林有了全新的认识。拙政园每个角度都是画，太美了！",
      helpful_count: 123,
      visit_date: Date.today - 11.days,
      data_version: '0',
      created_at: Time.current - 11.days,
      updated_at: Time.current - 11.days
    },
    {
      deep_travel_guide_id: guides["吴园林"].id,
      user_id: default_user_id,
      rating: 4.8,
      content: "很专业的讲解，吴导游18年的研究功底展现得淋漓尽致。讲解中还穿插了很多诗词典故，很有文化味道。唯一不足是时间有点紧，想再慢慢逛逛。",
      helpful_count: 67,
      visit_date: Date.today - 3.days,
      data_version: '0',
      created_at: Time.current - 3.days,
      updated_at: Time.current - 3.days
    }
  ]
  all_reviews.concat(吴园林_reviews)
end

# 批量插入所有评价
if all_reviews.any?
  DeepTravelReview.insert_all(all_reviews)
  puts "✓ 成功加载 #{all_reviews.size} 条评价"
else
  puts "⚠ 未找到匹配的讲解员，无法加载评价数据"
end

puts "✓ 深度旅行评价数据包加载完成"
