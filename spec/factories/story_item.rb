FactoryGirl.define do
  factory :story_item, class: SupplejackApi::SetItem do
    sequence(:record_id)
    sequence(:position)

    type 'text'
    sub_type 'heading'
    content {{
      value: 'foo'
    }}
    meta {{
      size: 1
    }}
  end
end
