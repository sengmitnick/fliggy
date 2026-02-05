# Validators 临时目录

## 目的
这个目录用于暂存从 v317 开始的验证器用例，这批用例目前存在错误难以修复，暂时移到这里以避免影响其他同事的开发和 PR 提交。

## 包含的验证器

### v301_v350 目录 (34 个)
**v317-v329 系列：**
- v317_book_spring_festival_train_ticket_validator.rb
- v318_book_national_day_attraction_hotel_package_validator.rb
- v319_book_summer_vacation_family_tour_validator.rb
- v320_book_winter_ski_resort_package_validator.rb
- v321_book_labor_day_short_trip_validator.rb
- v322_book_spring_flower_viewing_tour_validator.rb
- v323_book_summer_beach_resort_validator.rb
- v324_book_autumn_maple_viewing_tour_validator.rb
- v325_book_winter_ice_snow_tour_validator.rb
- v326_book_rainy_season_off_peak_tour_validator.rb
- v327_lavender_sunflower_tour_validator.rb
- v328_bird_watching_tour_validator.rb
- v329_fruit_picking_tour_validator.rb

**v330-v339 系列：**
- v330_mountain_climbing_equipment_validator.rb
- v331_diving_season_booking_validator.rb
- v332_christmas_theme_tour_validator.rb
- v333_new_year_countdown_validator.rb
- v334_valentine_romantic_package_validator.rb
- v335_mid_autumn_moon_tour_validator.rb
- v336_tibet_highland_tour_validator.rb
- v337_xinjiang_desert_adventure_validator.rb
- v338_yunnan_ethnic_tour_validator.rb
- v339_inner_mongolia_grassland_validator.rb

**v340-v350 系列：**
- v340_hainan_island_tour_validator.rb
- v341_book_northeast_ice_snow_tour_validator.rb
- v342_book_jiangnan_water_town_tour_validator.rb
- v343_book_guizhou_cave_adventure_validator.rb
- v344_book_guilin_landscape_tour_validator.rb
- v345_book_corporate_charter_flight_validator.rb
- v346_book_private_yacht_resort_validator.rb
- v347_book_first_class_world_tour_validator.rb
- v348_book_custom_private_tour_validator.rb
- v349_book_celebrity_route_validator.rb
- v350_book_three_generation_family_tour_validator.rb

### v351_v400 目录 (5 个)
- v351_book_company_team_building_validator.rb
- v352_book_wedding_group_validator.rb
- v353_book_graduation_trip_validator.rb
- v354_book_class_reunion_validator.rb
- v355_search_cheapest_flight_validator.rb

**总计**: 39 个验证器

## 迁移时间
迁移日期: 2026-02-01

## 后续计划
待问题修复后，将这些验证器重新移回对应的原目录：
- `app/validators/v301_v350/`
- `app/validators/v351_v400/`

## 注意事项
- 这些验证器暂时不会在 `rake validator:simulate` 中运行
- 不影响主项目的测试和验证流程
