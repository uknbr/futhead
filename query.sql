-- Strikers
select * from player where position in ('ST','CF') and potential > 80 and growth > 10 order by `potential` desc limit 10;

-- Goalkeeper
select * from player where position in ('GOL') and potential > 80 and growth > 10 order by `potential` desc limit 10;

-- Defenders
select * from player where position in ('CB') and potential > 80 and growth > 10 order by `potential` desc limit 10;

-- Back (Right)
select * from player where position in ('RB', 'RWB') and potential > 80 and growth > 10 order by `potential` desc limit 10;

-- Back (Left)
select * from player where position in ('LB', 'LWB') and potential > 80 and growth > 10 order by `potential` desc limit 10;

-- Midfield
select * from player where position in ('CAM', 'CM', 'CDM') and potential > 80 and growth > 10 order by `potential` desc limit 10;

-- Foward (Left)
select * from player where position in ('LW', 'LM') and potential > 80 and growth > 10 order by `potential` desc limit 10;

-- Foward (Right)
select * from player where position in ('RW', 'RM') and potential > 80 and growth > 10 order by `potential` desc limit 10;

select distinct position from player;


-- Team
-- GK > B. Dragowski (86)
-- RB > D. Iorfa (81)
-- CB > Juste (84)
-- CB > Tin Jedvaj (86)
-- LB > Robertson (84)
-- CAM > Nouri (84) / MEI > Manu Garcia (83)
-- CM > Hughes (85)
-- CM > Bazoer (88)
-- LW > Bergwijn (85) / LW > Vaclav Cerny (86)
-- RW > Victor Andrade (85)
-- ST > Iheanacho (85) / ST > Maxwel Cornet (85)


