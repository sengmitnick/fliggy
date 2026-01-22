# frozen_string_literal: true

namespace :tour_products do
  desc "Fix tour product images by adding Unsplash URLs"
  task fix_images: :environment do
    puts "开始修复 TourProduct 图片..."
    
    # Unsplash图片URL基础
    unsplash_keywords = {
      'attraction' => %w[landmark monument architecture tourist scenic],
      'hotel' => %w[hotel resort luxury accommodation bedroom],
      'tour' => %w[travel vacation adventure journey tourist],
      'package' => %w[vacation package holiday travel destination]
    }
    
    # 随机Unsplash图片ID列表（用于确保图片质量）
    unsplash_ids = [
      'Q1p7bh3SHj8', 'tZnbakTUcTI', '6M9xiVgkoN0', 'HOrhCnQsxnQ',
      'mpN7xjKQ_Ns', 'TrhLCn1abMU', 'TVllFyGaLEA', '4Mw7nkQDByk',
      'RCAhiGJsUUE', 'qmf9IWcOcDE', 'wtndoIe5jX8', '4amyOVm9oHc',
      'VviFtDJakYk', 'F2KRf_QfCqw', 'i5Kx0P8A0d4', 'dQ5G0h7sLno',
      '6-L5vBLWKT8', 'g5ZIgGdCx88', 'uN_qFM-eT_Q', '8bghKxNU1j0',
      'QwoNAhbmLLo', '7nrsVjvALnA', '4Yv84VgQkRM', 'pHANr-CpbYM',
      'L19BC2nxBmE', 'jDwHHjoRPqw', 'E4BcLxfXO8k', 'qf0nLMOYNfQ'
    ]
    
    count = 0
    TourProduct.find_in_batches(batch_size: 100) do |batch|
      batch.each do |product|
        # 如果已有image_url就跳过
        next if product.image_url.present?
        
        # 根据产品类型选择关键词
        keywords = unsplash_keywords[product.product_type] || ['travel']
        keyword = keywords.sample
        
        # 使用随机ID或搜索关键词
        if unsplash_ids.any?
          photo_id = unsplash_ids.sample
          image_url = "https://images.unsplash.com/photo-#{photo_id}?w=800&h=600&fit=crop"
        else
          image_url = "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop&q=80"
        end
        
        product.update_column(:image_url, image_url)
        count += 1
        
        print "\r已处理: #{count} 条记录" if count % 10 == 0
      end
    end
    
    puts "\n✅ 完成！共修复 #{count} 个 TourProduct 的图片"
    puts "图片来源: Unsplash"
  end
end
