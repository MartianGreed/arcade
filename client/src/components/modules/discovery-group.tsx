import { ArcadeGameHeaderProps, cn } from "@cartridge/ui-next";
import {
  ArcadeDiscoveryEvent,
  ArcadeDiscoveryEventProps,
} from "./discovery-event";
import { cva, VariantProps } from "class-variance-authority";
import { HTMLAttributes } from "react";
import ArcadeGameHeader from "./game-header";

interface ArcadeDiscoveryGroupProps
  extends HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof arcadeDiscoveryGroupVariants> {
  events: ArcadeDiscoveryEventProps[];
  game?: ArcadeGameHeaderProps;
  loading?: boolean;
  rounded?: boolean;
}

export const arcadeDiscoveryGroupVariants = cva(
  "select-none flex flex-col gap-y-px data-[rounded=true]:rounded data-[rounded=true]:overflow-hidden",
  {
    variants: {
      variant: {
        darkest: "",
        darker: "",
        dark: "",
        default: "",
        light: "",
        lighter: "",
        lightest: "",
        ghost: "",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  },
);

export const ArcadeDiscoveryGroup = ({
  game,
  events,
  loading,
  rounded,
  variant,
  className,
  color,
  onClick,
}: ArcadeDiscoveryGroupProps) => {
  return (
    <div
      data-rounded={rounded}
      className={cn(arcadeDiscoveryGroupVariants({ variant }), className)}
    >
      {game && <ArcadeGameHeader variant={variant} {...game} />}
      {events.map((event, index) => (
        <ArcadeDiscoveryEvent
          key={`${event.name}-${event.timestamp}-${index}`}
          loading={loading}
          className={className}
          variant={variant}
          color={color}
          onClick={onClick}
          {...event}
        />
      ))}
    </div>
  );
};
