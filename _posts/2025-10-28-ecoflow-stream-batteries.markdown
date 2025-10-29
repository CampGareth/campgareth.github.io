---
layout: post
title:  "Experiences with Ecoflow Stream Batteries"
date:   2025-10-28 19:00:00 +0000
categories: review
---

# Background

## History of Solar At Home

Over the past few decades people have been getting more environmentally conscious, and electricity prices have been going up. This has led many people to install solar panels at home to supply some of their electricity from green sources and reduce their bills. 

Historically this has only been possible for owners of traditional homes with £10-15k cash to spare. The panels used to be expensive as did scaffolding and the labour costs of getting a couple of trained electricians to work on your roof for a couple of days. Renters were out of luck as they didn't own the roof space or might not have roof space at all in the case of apartment dwellers. Landlords were unlikely to invest thousands of pounds to reduce their tenant's electricity bills without a direct return on investment.

Recently things have been changing. You can now get a single 500 Watt peak (Wp) solar panel for about £60-80 making a normal 4kWp array around £480-640. Labour costs are now the biggest line item in a traditional installation. Meanwhile legislation in countries like Germany has changed to legalise installing panels in easy to access locations such as balconies. Germany has also legalised feeding small amounts of power back into the grid, up to 800W if I remember correctly.

These changes have enabled "Balcony Solar" systems which are particularly useful for renters as they can be installed cheaply, transported during house moves, and provide a significant reduction on electricity bills. Ecoflow developed the first generation PowerStream Microinverter to cater to this market. It had two 400W solar inputs and could output 800W to the mains supply in your home.

One aspect of solar panels that isn't great is the sun shines when you don't need it. Usually peak output is in the midday to 4pm range when people may not be at home. You can schedule appliances to run in this period but to make the most of the energy you need to store it in a battery and use it when you're at home or when electricity is most expensive, e.g. the 4-7pm demand peak as people cook dinner. Ecoflow's first generation PowerStream had a battery connector to allow you to store excess power in one of their portable battery products, however for the second generation they removed that connector and made the PowerStream a pure microinverter. They also released the Ecoflow Stream lineup.

## What is an Ecoflow Stream Battery?

It's a grid-tie hybrid solar inverter with an integrated 1.9kWh battery. There are a few different models but the top spec one can receive 2kW of input power from 4 x 500W solar panel inputs, charge the internal battery from solar or mains, and output 1200W (800W in the UK) back to the grid from the battery or solar inputs. It has wifi and bluetooth connectivity with an app to manage the device. It can pair with other Stream batteries to function as a larger battery, transferring power between units using your home wiring. There are integrated plugs on each unit with a 1200W power limit (rising to 2300W if two units are combined) plus power monitoring and remote control. It can be made aware of your electricity tariff to charge from the mains when it's cheap and cover your consumption when it's expensive. It can also pair with a whole-home power monitor or smart plugs (more on that later) to cover your whole home power consumption.

Phew. That's a lot of features, but you're all caught up now.

# Review

## The Setup

Firstly I bought all of this myself. Ecoflow did not sponsor me or provide any equipment.

I've bought 3 Stream batteries, one Ultra, one Max and one AC Pro. I also bought 3 Ecoflow x Shelly Smart Plugs (UK). The Ultra has every feature including 4 solar inputs with 500W input each and 2 mains sockets on the rear. The Max has 2 solar inputs and 1 socket, while the AC Pro has no solar inputs and 2 sockets. There's also an AC (non-Pro) which has no inputs or sockets, it's just a grid tie battery. I haven't bought a whole-home power monitor as I rent my home and can't get to the wires running to my CU to attach the current-sensing clamps.

The Ultra is in my living room with 2 of the solar inputs in use. Each input has 2 x 450W bifacial solar panels connected in parallel and mounted vertically on a south-facing fence for a total of 1800Wp, though the highest the inputs support is 1000W. The Ultra powers my TV, games consoles etc and an electric heater. The AC Pro is in my office powering my desk and a 200W window heat pump. The Max is in my bedroom with its 2 solar inputs each connected to a 50W flexible solar panel stuffed into a skylight for 100Wp. The Max powers a 500W electric heater with a timer. Each Stream unit is passively cooled with a large heatsink on the rear so they are mostly silent although you can sometimes hear coil whine and relays clicking.

Before buying the Streams I had been trying to figure out the best way to add batteries to my home. I had solar panels and an Ecoflow PowerStream but on sunny days I was exporting a lot of energy to the grid and not being paid for it since my setup had no MCS certification. I tried to integrated a dumb 12V LFP battery via the first generation PowerStream's battery port which worked but since the PowerStream couldn't charge it I had to bodge together some automation using a battery charger, a smart plug and Home Assistant. It didn't work very well as it could only discharge 100W from the battery and there was no way to scale the charger's power consumption to match spare solar energy so it either left export on the table or drew from the grid. I had also considered adding an inverter/charger and battery to my office which could be charged on cheap rate electricity then discharged during expensive periods however I don't spend every day in that office so for half the week it wouldn't be providing any benefits and this made the purchase difficult to justify. If I was going to add a battery in that location it should benefit the rest of the house somehow.

## Starting simple, how well does each battery work?

Individually they work very well. The most basic mode of operation is Self-Powered mode where the battery stores excess solar power from its built in solar inputs and uses it to power its built in mains outputs. It can be run off-grid in this mode with the caveat that 1.9kWh isn't a lot of capacity. If you were looking to run your whole home off solar power batteries with tens of kWh are more appropriate. Likewise if you max out the solar inputs with 2kW of input then I'm not sure if the battery would be able to receive the full power, and if it did it would rapidly fill up.

What if you want to power other devices that aren't directly connected? That's where the grid-tie bit comes in. You can plug the input/output port (which has a custom connector) into your home wiring to feed power to devices elsewhere in your home. Officially the batteries must be hardwired with a fused spur. It's possible to wire them to a standard 3-pin plug however I can't recommend anyone do this. They say safety regulations are written in blood, meaning someone got hurt badly enough to cause regulations to be written so they are ignored at your own peril. Anyway, with the input/output port connected you can pair a smart power meter monitoring your home consumption and this has the best results as the battery is able to supply whatever your house demands up to 800W (in the UK) without going over and exporting energy. If you don't install a power meter you can use "semi-automated monitoring" where you program your home base load into the Ecoflow app and the battery will supply that. It's not a single value, you can say your home draws 100W between 10pm and 8am then 200W 8am-10pm. If you have a smart meter at home with an in-home-display you can use this to get close to zero energy drawn from or exported to the grid but it won't be perfect. As an example on some days my partner works from home so the daytime consumption is higher but I can't program in a weekly schedule for base load, only a daily one.

What are you meant to do about more dynamic loads? Ecoflow sells smart plugs that can monitor a single socket's consumption and send the data to your Stream battery so it can output base load and smart plug consumption into the wiring. For example if your base load is configured at 100W and the smart plug reports 200W consumption then the battery will output 300W to the mains. This is theoretical at the moment as I've been unable to pair my UK smart plugs with the batteries. I've got a support ticket open with Ecoflow about this but it looks like two issues, the app not recognising the smart plugs as compatible with the batteries (bluetooth scan yields no devices, but Android's bluetooth scan shows the plugs), and the plugs not enabling bluetooth on a factory reset.

Earlier I mentioned a Stream AC model that doesn't have solar inputs and that battery running standalone can't work in Self-Consumption mode, what's the point then? Electricity tariffs in the UK come in three forms I'll call Flat, Scheduled and Dynamic. Flat means you pay for example 28p per kWh regardless of when you consume. Scheduled means you pay perhaps 15p per kWh overnight and 30p per kWh in the daytime. Dynamic is things like Octopus Agile or Intelligent Octopus Go where you have rates that vary throughout the day but aren't on a fixed schedule. If you're on a scheduled tariff you could save money by charging a battery during the cheap periods and discharging the battery during the expensive periods. That's possible with any Ecoflow Stream including the AC model using the Custom operating mode. For Dynamic tariffs you really need the battery to be aware of your tariff and that's possible though I'll talk about that later.

# WIP

## What happens if you buy multiple?

I started with the living room Stream Ultra and my office AC Pro. When adding them to the same Space in the Ecoflow app they function as a single big battery. That means they try to share the workload and maintain a similar State of Charge though this is only a loose goal and the individual Streams can get quite unbalanced. As an example right now my bedroom Stream Max is at 22% and outputting 530W to a directly connected load, my office AC Pro is at 30% and doing nothing, and my living room Ultra is at 56% and outputting 120W to grid-tie and 30W to directly connected loads. Let's break down how they behave.

Charging via the grid-tie input is the most well-balanced mode as each battery charges individually using their onboard 1050W chargers. You can limit the overall system charge rate via the app if you have a power limit on your grid connection.


During solar charging the Ultra will lead the other batteries by a few percent. It will mostly charge itself then when it gets too far ahead of the others it will increase its grid-tie output and the other batteries will absorb the energy. It's using your house wiring to transfer energy between devices which incurs some efficiency penalties but as a guess based on each device being passively cooled it's probably 85%+ efficient and really very cool. 

During grid-tie discharging the system picks the battery with the highest SoC to provide the power. During local discharging though the locally connected battery is used as the primary source and only when that battery has been drained does another battery's grid-tie output increase to provide the power.

Both charging and discharging with multiple batteries highlight a limitation. In the UK each battery can at most output 800W on its grid-tie output and all batteries combined can at most output 800W on grid-tie. I think this second point is a safety thing as Ecoflow don't know the wiring capacity between batteries, but a full system of six batteries all outputting 800W on the same circuit could exceed the current rating of the wiring. The 800W limit is quite irritating if you have loads greater than 800W attached to batteries as the load will drain the local battery first then remote batteries can only supply 800W, so a 1200W device could be 

<!-- Since this involes the inverters and chargers in each device there are limits. Each battery can at most charge at 1050W from AC sources and the AC output is limited to the grid-tie maximum which is 800W in the UK. I think this means with 2kW of solar input to my Ultra it would output 800W for the other two batteries to consume then take ~1000W input for itself and curtail the solar inputs by 200W. For an unbalanced system with lots of batteries only one of which has solar input this could create some very unoptimal situations where the solar-input battery charges long before the others as they're all sharing the 800W output by the solar-input battery, then since there's nowhere for the extra solar power to go it gets curtailed. 

 This brings me on to the second limitation, there is a grid-tie output limit per-battery and also for the whole system, both of which are 800W in the UK.  -->


Pretty well, some quirks. How does it decide which battery to charge? Maximum 1200W output only to connected devices, 800W into grid maximum from all batteries combined. Efficiency? 

## What about the app functions?

Broadly good, lots of information but minimal control over batteries. Built to be hands-off. Talk about delays in scheduling.  

## What about the AI functions?

Talk about what it does, uncertainty over higher AI tiers, Octopus Agile combining 30 minute slots into 60 minute average slots.

## Pairing with smart plugs?

Doesn't work properly today. Generally bad experience for an officially supported and advertised combination

## Competition

Competition's a lot cheaper per kWh, but less plug and play.

## Recommend them?

Yes! Maybe not at full price, try ebay refurbished units.