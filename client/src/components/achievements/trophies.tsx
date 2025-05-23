import { AchievementCard } from "@cartridge/ui-next";
import { Item } from "@/hooks/achievements";
import { useCallback, useEffect, useMemo, useState } from "react";
import { GameModel } from "@bal7hazar/arcade-sdk";
import { useArcade } from "@/hooks/arcade";
import { constants, getChecksumAddress } from "starknet";
import { toast } from "sonner";
import { useAccount } from "@starknet-react/core";
import ControllerConnector from "@cartridge/connector/controller";

const HIDDEN_GROUP = "Hidden";

export function Trophies({
  address,
  achievements,
  softview,
  enabled,
  game,
  pins,
}: {
  address: string;
  achievements: Item[];
  softview: boolean;
  enabled: boolean;
  game: GameModel | undefined;
  pins: { [playerId: string]: string[] };
  earnings: number;
}) {
  const [groups, setGroups] = useState<{ [key: string]: Item[] }>({});

  useEffect(() => {
    const groups: { [key: string]: Item[] } = {};
    achievements.forEach((achievement) => {
      // If the achievement is hidden it should be shown in a dedicated group
      const group =
        achievement.hidden && !achievement.completed
          ? HIDDEN_GROUP
          : achievement.group;
      groups[group] = groups[group] || [];
      groups[group].push(achievement);
      groups[group]
        .sort((a, b) => a.id.localeCompare(b.id))
        .sort((a, b) => a.index - b.index);
    });
    setGroups(groups);
  }, [achievements]);

  return (
    <div className="flex flex-col gap-3 lg:gap-4">
      {Object.entries(groups)
        .filter(([group]) => group !== HIDDEN_GROUP)
        .map(([group, items]) => (
          <Group
            key={group}
            address={address}
            group={group}
            items={items}
            softview={softview}
            enabled={enabled}
            game={game}
            pins={pins}
          />
        ))}
      <Group
        key={HIDDEN_GROUP}
        address={address}
        group={HIDDEN_GROUP}
        items={(groups[HIDDEN_GROUP] || []).sort(
          (a, b) => a.earning - b.earning,
        )}
        softview={softview}
        enabled={enabled}
        game={game}
        pins={pins}
      />
    </div>
  );
}

function Group({
  group,
  address,
  items,
  softview,
  enabled,
  game,
  pins,
}: {
  group: string;
  address: string;
  items: Item[];
  softview: boolean;
  enabled: boolean;
  game: GameModel | undefined;
  pins: { [playerId: string]: string[] };
}) {
  const { account, connector } = useAccount();
  const { provider } = useArcade();

  const handlePin = useCallback(
    (
      pinned: boolean,
      achievementId: string,
      setLoading: (loading: boolean) => void,
    ) => {
      if (!account || (!enabled && !pinned)) return;
      const controller = (connector as ControllerConnector)?.controller;
      if (!controller) return;
      const process = async () => {
        setLoading(true);
        try {
          const calls = pinned
            ? provider.social.unpin({ achievementId })
            : provider.social.pin({ achievementId });
          controller.switchStarknetChain(constants.StarknetChainId.SN_MAIN);
          const res = await account.execute(calls);
          if (res) {
            toast.success(
              `Trophy ${pinned ? "unpinned" : "pinned"} successfully`,
            );
          }
        } catch (error) {
          console.error(error);
          toast.error(`Failed to ${pinned ? "unpin" : "pin"} trophy`);
        } finally {
          setLoading(false);
        }
      };
      process();
    },
    [enabled, account, connector],
  );

  const achievements = useMemo(() => {
    return items.map((item) => {
      const pinned =
        pins[getChecksumAddress(address)]?.includes(item.id) && item.completed;
      return {
        id: item.id,
        index: item.index,
        completed: item.completed,
        content: {
          points: item.earning,
          difficulty: parseFloat(item.percentage),
          hidden: item.hidden,
          icon: item.hidden && !item.completed ? undefined : item.icon,
          title: item.title,
          description: item.description,
          tasks: item.tasks,
          timestamp: item.completed ? item.timestamp : undefined,
        },
        pin:
          softview || !item.completed
            ? undefined
            : {
                pinned: pinned,
                achievementId: item.id,
                disabled: !pinned && !enabled,
                onClick: handlePin,
              },
        share:
          softview ||
          !item.completed ||
          !game?.socials.website ||
          !game?.socials.twitter
            ? undefined
            : {
                website: game?.socials.website,
                twitter: game?.socials.twitter,
                timestamp: item.timestamp,
                points: item.earning,
                difficulty: parseFloat(item.percentage),
                title: item.title,
              },
      };
    });
  }, [items, pins, handlePin]);

  return <AchievementCard name={group} achievements={achievements} />;
}
