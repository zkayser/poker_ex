import MainView from './main-view';
import RoomIndexView from './room/index';
import PlayerShowView from './player/show';
import PrivateRoomNewView from './private-room/new';
import PrivateRoomShowView from './private-room/show';

const views = {
  RoomIndexView,
  PlayerShowView,
  PrivateRoomNewView,
  PrivateRoomShowView,
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}