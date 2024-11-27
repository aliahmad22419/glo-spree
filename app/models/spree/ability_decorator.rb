module SpreeAbilities
    module AbilityActivator
    private
    def abilities_to_register
      super << Spree::UserAccessAbility
    end
  end
end

Spree::Ability.prepend SpreeAbilities::AbilityActivator
